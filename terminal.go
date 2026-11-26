package main

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"os"
	"strconv"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/huh"
	"github.com/charmbracelet/lipgloss"
	"github.com/charmbracelet/x/term"
	"github.com/muesli/termenv"
)

type language string

const (
	spanish language = "es"
	english language = "en"
)

func (lang language) text(es, en string) string {
	if lang == english {
		return en
	}
	return es
}

type terminal struct {
	language
	in          io.Reader
	out         io.Writer
	scanner     *bufio.Scanner
	interactive bool
	height      int
	renderer    *lipgloss.Renderer
	opening     bool
	intro       string
}

func newTerminal(input io.Reader, output io.Writer, lang language, plain bool) (terminal, func()) {
	menu := terminal{language: lang, in: input, out: output, scanner: bufio.NewScanner(input)}
	inFile, inputIsFile := input.(*os.File)
	outFile, outputIsFile := output.(*os.File)
	if plain || os.Getenv("TERM") == "dumb" || !inputIsFile || !outputIsFile ||
		!term.IsTerminal(inFile.Fd()) || !term.IsTerminal(outFile.Fd()) {
		return menu, func() {}
	}
	restore, err := termenv.EnableVirtualTerminalProcessing(termenv.NewOutput(outFile))
	if err != nil {
		return menu, func() {}
	}
	_, menu.height, _ = term.GetSize(outFile.Fd())
	menu.interactive = true
	menu.renderer = lipgloss.NewRenderer(output)
	return menu, func() { _ = restore() }
}

func (menu terminal) accent() lipgloss.Style {
	return menu.renderer.NewStyle().Foreground(lipgloss.Color("#FA8072"))
}

func (menu terminal) slogan() {
	style := menu.renderer.NewStyle().Foreground(lipgloss.Color("#808080"))
	fmt.Fprintln(menu.out, "  "+style.Render(menu.text(
		"Especificaciones breves, gran flexibilidad.",
		"Short specs, plenty of flexibility.",
	)))
	fmt.Fprintln(menu.out)
}

func (menu terminal) status(symbol, color, message string) {
	if menu.interactive {
		symbol = menu.renderer.NewStyle().Foreground(lipgloss.Color(color)).Render(symbol)
		message = symbol + " " + message
	}
	fmt.Fprintln(menu.out, message)
}

func (menu terminal) form(field huh.Field) error {
	theme := huh.ThemeBase()
	theme.Focused.Base = menu.renderer.NewStyle().PaddingLeft(2)
	theme.Focused.Title = menu.renderer.NewStyle().Bold(true)
	theme.Focused.Description = menu.renderer.NewStyle().Faint(true)
	theme.Focused.SelectSelector = menu.accent().SetString("› ")
	theme.Focused.SelectedOption = menu.accent().Bold(true)
	theme.Focused.TextInput.Prompt = menu.accent()
	theme.Blurred = theme.Focused
	keys := huh.NewDefaultKeyMap()
	keys.Quit.SetKeys("esc", "ctrl+c")
	form := huh.NewForm(huh.NewGroup(field)).WithTheme(theme).WithKeyMap(keys).
		WithInput(menu.in).WithOutput(menu.out).WithAccessible(false).WithShowHelp(false)
	var err error
	if menu.opening {
		screen := &openingForm{form: form, title: menu.accent().Bold(true), intro: menu.intro}
		form.SubmitCmd, form.CancelCmd = tea.Quit, tea.Quit
		_, err = tea.NewProgram(screen, tea.WithInput(menu.in), tea.WithOutput(menu.out)).Run()
		fmt.Fprint(menu.out, screen.header("◆"))
	} else {
		err = form.Run()
	}
	if form.State == huh.StateAborted || errors.Is(err, huh.ErrUserAborted) {
		return errors.New(menu.text("instalación cancelada", "installation cancelled"))
	}
	return err
}

type openingForm struct {
	form  *huh.Form
	title lipgloss.Style
	intro string
	frame int
}

type diamondTick struct{}

func nextDiamondFrame() tea.Cmd {
	return tea.Tick(180*time.Millisecond, func(time.Time) tea.Msg { return diamondTick{} })
}

func (screen *openingForm) Init() tea.Cmd {
	return tea.Batch(screen.form.Init(), nextDiamondFrame())
}

func (screen *openingForm) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	if _, ok := msg.(diamondTick); ok {
		screen.frame++
		if screen.frame < 6 && screen.form.State == huh.StateNormal {
			return screen, nextDiamondFrame()
		}
		return screen, nil
	}
	_, cmd := screen.form.Update(msg)
	return screen, cmd
}

func (screen *openingForm) header(diamond string) string {
	return "\n" + screen.title.Render(diamond+" LITESPEC  "+version) + "\n" + screen.intro
}

func (screen *openingForm) View() string {
	if screen.form.State != huh.StateNormal {
		return ""
	}
	diamond := "◆"
	if screen.frame%2 == 1 {
		diamond = " "
	}
	return screen.header(diamond) + screen.form.View()
}

func (menu terminal) choose(title, prompt string, options []string, selected int, invalid string) (int, error) {
	if menu.interactive {
		items := make([]huh.Option[int], len(options))
		for i, label := range options {
			items[i] = huh.NewOption(label, i)
		}
		choice := max(0, selected)
		height := min(len(options)+3, 11)
		if menu.height > 0 {
			height = min(height, max(4, menu.height-4))
		}
		field := huh.NewSelect[int]().Title(title).Description(menu.text(
			"↑ ↓ Moverse    Enter Elegir    Esc Cancelar",
			"↑ ↓ Move    Enter Choose    Esc Cancel",
		)).Options(items...).Value(&choice).Filtering(false).Height(height)
		err := menu.form(field)
		return choice, err
	}
	fmt.Fprintln(menu.out, title)
	for i, option := range options {
		fmt.Fprintf(menu.out, "%2d) %s\n", i+1, option)
	}
	answer, err := menu.ask(prompt)
	if err != nil {
		return 0, err
	}
	if answer == "" && selected >= 0 {
		return selected, nil
	}
	index, err := strconv.Atoi(answer)
	if err != nil || index < 1 || index > len(options) || strconv.Itoa(index) != answer {
		return 0, errors.New(invalid)
	}
	return index - 1, nil
}

func (menu terminal) ask(label string) (string, error) {
	if menu.interactive {
		var answer string
		field := huh.NewInput().Title(label).Prompt("› ").
			Description(menu.text("Enter Continuar    Esc Cancelar", "Enter Continue    Esc Cancel")).Value(&answer)
		err := menu.form(field)
		return strings.TrimSpace(answer), err
	}
	fmt.Fprint(menu.out, label+": ")
	if !menu.scanner.Scan() {
		if err := menu.scanner.Err(); err != nil {
			return "", err
		}
		return "", io.EOF
	}
	return strings.TrimSpace(menu.scanner.Text()), nil
}
