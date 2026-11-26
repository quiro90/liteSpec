package main

import (
	"embed"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
)

//go:embed lite.spec.steps/litespec-*/SKILL.md lite.spec.steps/litespec-shared/*.md
var packageFiles embed.FS

var version = "dev"

const usage = "litespec [init [--project <path>] [--lang es|en] [--plain]] | litespec --version"

func main() {
	executable, _ := os.Executable()
	if err := run(os.Args[1:], os.Stdin, os.Stdout, executable); err != nil {
		fmt.Fprintln(os.Stderr, "LiteSpec:", err)
		os.Exit(1)
	}
}

func run(args []string, input io.Reader, out io.Writer, executable string) error {
	if len(args) == 1 {
		switch args[0] {
		case "--version", "-version", "version":
			fmt.Fprintln(out, version)
			return nil
		case "--help", "-h", "help":
			fmt.Fprintln(out, "Uso / Usage:", usage)
			return nil
		}
	}
	if len(args) > 0 {
		if args[0] != "init" {
			return fmt.Errorf("comando desconocido / unknown command %q. %s", args[0], usage)
		}
		args = args[1:]
	}
	flags := flag.NewFlagSet("init", flag.ContinueOnError)
	flags.SetOutput(io.Discard)
	project := flags.String("project", ".", "")
	lang := flags.String("lang", "", "")
	plain := flags.Bool("plain", false, "")
	if err := flags.Parse(args); errors.Is(err, flag.ErrHelp) {
		fmt.Fprintln(out, "Uso / Usage:", usage)
		return nil
	} else if err != nil {
		return err
	}
	if flags.NArg() != 0 || *project == "" {
		return errors.New(usage)
	}
	if *lang != "" && *lang != string(spanish) && *lang != string(english) {
		return errors.New("idioma inválido / invalid language (es, en)")
	}

	menu, restore := newTerminal(input, out, language(*lang), *plain)
	defer restore()
	var intro strings.Builder
	if menu.interactive {
		fmt.Fprint(out, "\x1b[2J\x1b[H")
		menu.opening = true
		if *lang == "" {
			choice, err := menu.choose("Idioma / Language", "", []string{"Español", "English"}, 0, "")
			if err != nil {
				return err
			}
			menu.language = []language{spanish, english}[choice]
			menu.opening = false
		}
	}
	display := menu
	if menu.opening {
		display.out = &intro
	}
	if menu.interactive {
		display.slogan()
	}

	projectPath, err := filepath.Abs(*project)
	if err != nil {
		return err
	}
	projectPath, err = filepath.EvalSymlinks(projectPath)
	if err != nil {
		return err
	}
	root, err := os.OpenRoot(projectPath)
	if err != nil {
		return err
	}
	defer root.Close()

	if menu.interactive {
		fmt.Fprintf(display.out, menu.text("Proyecto: %s\n", "Project: %s\n"), projectPath)
	} else {
		fmt.Fprintf(out, menu.text("LiteSpec %s - proyecto: %s\n", "LiteSpec %s - project: %s\n"), version, projectPath)
	}
	if destinations := installedSkillDestinations(root); len(destinations) > 0 {
		display.status("✓", "#64C49D", fmt.Sprintf(menu.text(
			"Se encontró una instalación de LiteSpec en %s.",
			"Found an existing LiteSpec installation in %s.",
		), strings.Join(destinations, ", ")))
		fmt.Fprintln(display.out, menu.text(
			"Se actualizarán las skills del agente que elijas. Sus perfiles se ajustarán a tus opciones. Se conservarán los demás archivos y los datos en .litespec/.",
			"The selected agent's skills and profiles will be updated to match your choices. Extra files and data in .litespec/ will be preserved.",
		))
	} else {
		display.status("○", "#FA8072", menu.text("Primera instalación en este proyecto.", "First installation in this project."))
	}
	fmt.Fprintln(display.out, menu.text(
		"Aviso: LiteSpec es experimental. Revisa las specs, los cambios y las verificaciones del agente antes de confiar en ellos.",
		"LiteSpec is experimental. Review agent-produced specs, changes, and checks before relying on them.",
	))
	if menu.interactive {
		fmt.Fprintln(display.out)
	}
	options := make([]string, len(agents))
	for index, agent := range agents {
		label := menu.text("Clásico", "Classic")
		if agent.native != "" || agent.invocation != "" {
			label += " / " + menu.text("Adaptive experimental", "Experimental Adaptive")
		}
		options[index] = fmt.Sprintf("%-15s %s", agent.name, label)
	}
	menu.intro = intro.String()
	choice, err := menu.choose(menu.text("Elegí un agente", "Choose an agent"), menu.text("Agente [1-13]", "Agent [1-13]"),
		options, -1, menu.text("selección inválida", "invalid selection"))
	if err != nil {
		return err
	}
	menu.opening = false
	return install(root, menu, agents[choice], executable)
}
