package main

import (
	"bytes"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"testing"
	"time"

	"github.com/charmbracelet/lipgloss"
	"github.com/muesli/termenv"
)

func invoke(t *testing.T, project, executable, input string) string {
	t.Helper()
	var output bytes.Buffer
	err := run([]string{"init", "--project", project}, strings.NewReader(input), &output, executable)
	if err != nil {
		t.Fatalf("%v\n%s", err, output.String())
	}
	return output.String()
}

func readProject(t *testing.T, project, name string) string {
	t.Helper()
	data, err := os.ReadFile(filepath.Join(project, name))
	if err != nil {
		t.Fatal(err)
	}
	return string(data)
}

func expectMissing(t *testing.T, project, name string) {
	t.Helper()
	if _, err := os.Lstat(filepath.Join(project, name)); !os.IsNotExist(err) {
		t.Fatalf("expected %s to be absent, got %v", name, err)
	}
}

func saveProject(t *testing.T, project, name, content string) {
	t.Helper()
	target := filepath.Join(project, name)
	if err := os.MkdirAll(filepath.Dir(target), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(target, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
}

func TestInstallsEmbeddedSkillsForAllAgents(t *testing.T) {
	destinations := []string{
		".agents", ".claude", ".github", ".cursor", ".opencode", ".qoder", ".gemini",
		".qwen", ".cline", ".devin", ".ade", ".agents", ".minimax",
	}
	for index, destination := range destinations {
		t.Run(fmt.Sprint(index+1), func(t *testing.T) {
			project := t.TempDir()
			input := fmt.Sprintf("%d\n", index+1)
			switch index + 1 {
			case 1, 2:
				input += "\n\n"
			case 3, 4, 5, 7, 8:
				input += "\n"
			}
			saveProject(t, project, ".litespec/docs/notes.md", "project notes")
			saveProject(t, project, destination+"/skills/litespec-explore/extra.md", "personal notes")
			output := invoke(t, project, "", input)
			if !strings.Contains(output, "Modo: Clásico") {
				t.Fatal(output)
			}
			if strings.Contains(output, "Se encontró una instalación") {
				t.Fatalf("project notes or other skills should not trigger a reinstall notice:\n%s", output)
			}
			count := 0
			err := fs.WalkDir(packageFiles, sourceTree, func(name string, entry fs.DirEntry, err error) error {
				if err != nil || entry.IsDir() {
					return err
				}
				expected, err := packageFiles.ReadFile(name)
				if err != nil {
					return err
				}
				actual := readProject(t, project, destination+"/skills/"+strings.TrimPrefix(name, sourceTree+"/"))
				if actual != string(expected) {
					t.Errorf("installed file differs from embedded file: %s", name)
				}
				count++
				return nil
			})
			if err != nil || count < 17 {
				t.Fatalf("expected all packaged files, got %d: %v", count, err)
			}
			if readProject(t, project, ".litespec/docs/notes.md") != "project notes" ||
				readProject(t, project, destination+"/skills/litespec-explore/extra.md") != "personal notes" {
				t.Fatal("project files were modified")
			}
			expectMissing(t, project, sourceTree)
			expectMissing(t, project, ".gitignore")
			expectMissing(t, project, installLock)
		})
	}
}

func TestInstallerShowsVersionAndExistingInstallBeforeMenu(t *testing.T) {
	project := t.TempDir()
	existing := []string{
		".agents/skills/litespec-explore/SKILL.md",
		".claude/skills/litespec-shared/protocol.md",
	}
	for _, file := range existing {
		saveProject(t, project, file, "previous installation")
	}
	var output bytes.Buffer
	err := run([]string{"--version"}, strings.NewReader(""), &output, "")
	if err != nil || strings.TrimSpace(output.String()) != version {
		t.Fatalf("unexpected version: %q (%v)", output.String(), err)
	}

	output.Reset()
	err = run([]string{"init", "--project", project}, strings.NewReader(""), &output, "")
	if err == nil {
		t.Fatal("expected cancellation at the agent prompt")
	}
	display := output.String()
	notice := strings.Index(display, "Se encontró una instalación de LiteSpec en .agents/skills/, .claude/skills/.")
	menu := strings.Index(display, "1) Codex")
	if !strings.HasPrefix(display, "LiteSpec "+version+" - proyecto: ") || notice < 0 || menu < notice {
		t.Fatalf("expected version and a single notice listing both destinations before the menu:\n%s", display)
	}
	for _, file := range existing {
		if readProject(t, project, file) != "previous installation" {
			t.Fatal("showing the notice should not modify an existing installation")
		}
	}
}

func TestNumberedEnglishInstaller(t *testing.T) {
	project := t.TempDir()
	saveProject(t, project, ".gitignore", "# existing rule\n")
	var output bytes.Buffer
	input := strings.NewReader("1\n2\n1\n\nhigh\ny\n")
	err := run([]string{"init", "--project", project, "--plain", "--lang", "en"}, input, &output, "")
	if err != nil {
		t.Fatalf("%v\n%s", err, output.String())
	}
	for _, message := range []string{"First installation in this project.", "Classic / Experimental Adaptive",
		"Step execution", "Experimental Adaptive · Delegate Easy steps", "Internal skill delegation",
		"easy - model", "Agent: Codex | Mode: Experimental Adaptive", "7 rules added."} {
		if !strings.Contains(output.String(), message) {
			t.Errorf("missing %q in output:\n%s", message, output.String())
		}
	}
	if strings.Contains(output.String(), "\x1b") || strings.Contains(output.String(), "Idioma / Language") {
		t.Fatalf("plain mode should use the original input sequence:\n%s", output.String())
	}
	readProject(t, project, ".codex/agents/litespec-easy.toml")
}

func TestArrowSelectorUsesTheHighlightedOption(t *testing.T) {
	for _, test := range []struct {
		name    string
		opening bool
	}{
		{"standard menu", false},
		{"opening animation", true},
	} {
		t.Run(test.name, func(t *testing.T) {
			var output bytes.Buffer
			menu := terminal{
				language: english, in: strings.NewReader("\x1b[B\r"), out: &output, interactive: true, opening: test.opening,
				renderer: lipgloss.NewRenderer(&output, termenv.WithProfile(termenv.TrueColor)),
			}
			selected, err := menu.choose("Idioma / Language", "", []string{"Español", "English"}, 0, "")
			if err != nil || selected != 1 {
				t.Fatalf("down and Enter selected %d, expected English: %v\n%s", selected, err, output.String())
			}
		})
	}
}

type menuTestOutput struct {
	bytes.Buffer
	hint string
	seen chan struct{}
}

func (out *menuTestOutput) Write(data []byte) (int, error) {
	n, err := out.Buffer.Write(data)
	if out.seen != nil && strings.Contains(out.String(), out.hint) {
		close(out.seen)
		out.seen = nil
	}
	return n, err
}

func TestAgentMultiSelectUsesSpaceInBothLanguages(t *testing.T) {
	for _, test := range []struct {
		lang    language
		opening bool
		hint    string
	}{
		{spanish, false, "[Espacio] Marcar"},
		{english, true, "[Space] Mark"},
	} {
		t.Run(string(test.lang), func(t *testing.T) {
			input, keys := io.Pipe()
			defer input.Close()
			seen := make(chan struct{})
			output := &menuTestOutput{hint: test.hint, seen: seen}
			go func() {
				defer keys.Close()
				select {
				case <-seen:
				case <-time.After(3 * time.Second):
				}
				_, _ = io.WriteString(keys, "\r \x1b[B\x1b[B \r")
			}()
			menu := terminal{
				language: test.lang, interactive: true, opening: test.opening,
				in: input, out: output,
				renderer: lipgloss.NewRenderer(output, termenv.WithProfile(termenv.TrueColor)),
			}
			selected, err := menu.chooseAgents([]string{"Codex", "Claude Code", "Zed"})
			if err != nil || !slices.Equal(selected, []int{0, 2}) || !strings.Contains(output.String(), test.hint) {
				t.Fatalf("selected %v, expected Codex and Zed with hint %q: %v\n%s", selected, test.hint, err, output.String())
			}
		})
	}
}

func TestInstallsMultipleAgentsWithOneGitignorePrompt(t *testing.T) {
	t.Setenv("GIT_DIR", filepath.Join(t.TempDir(), "missing"))
	project := t.TempDir()
	saveProject(t, project, ".gitignore", "# existing rule\n")
	saveProject(t, project, ".cursor/skills/litespec-explore/SKILL.md", "previous install")
	output := invoke(t, project, "", "12, 1, 2, 12\n1\n1\n2\n1\n\n\ns\n")
	ignorePrompt := "¿Qué excluir en .gitignore?"
	for _, message := range []string{"Agente: Codex | Modo: Clásico", "Agente: Claude Code | Modo: Adaptive experimental", "Agente: Zed | Modo: Clásico"} {
		summary := strings.Index(output, message)
		if summary < 0 || summary > strings.Index(output, ignorePrompt) {
			t.Fatalf("expected %q before the .gitignore prompt:\n%s", message, output)
		}
	}
	if strings.Count(output, ignorePrompt) != 1 || strings.Count(output, "  • .agents/skills/\n") != 1 {
		t.Fatalf("expected one prompt with each destination listed once:\n%s", output)
	}
	readProject(t, project, ".agents/skills/litespec-explore/SKILL.md")
	readProject(t, project, ".claude/skills/litespec-explore/SKILL.md")
	readProject(t, project, ".claude/agents/litespec-easy.md")
	expectMissing(t, project, ".codex/agents/litespec-easy.toml")
	ignored := readProject(t, project, ".gitignore")
	if strings.Count(ignored, "/.agents/skills/litespec-explore/\n") != 1 ||
		strings.Count(ignored, "/.claude/skills/litespec-explore/\n") != 1 || strings.Contains(ignored, ".cursor/") {
		t.Fatalf("expected ignore rules only for the selected destinations:\n%s", ignored)
	}
}

func TestNativeProfilesAndReconfiguration(t *testing.T) {
	for _, test := range []struct {
		choice, destination, profileDir, extension, model, effort string
	}{
		{"1", ".agents/skills", ".codex/agents", ".toml", `model = "gpt-6.2-sol"`, `model_reasoning_effort = "high"`},
		{"2", ".claude/skills", ".claude/agents", ".md", "model: 'sonnet'", "effort: high"},
	} {
		t.Run(test.profileDir, func(t *testing.T) {
			project := t.TempDir()
			marker := test.destination + "/litespec-shared/delegation-active.md"
			easy := test.profileDir + "/litespec-easy" + test.extension
			search := test.profileDir + "/litespec-search" + test.extension
			plan := test.profileDir + "/litespec-plan" + test.extension
			extra := test.profileDir + "/unrelated.md"
			saveProject(t, project, extra, "other profile")
			output := invoke(t, project, "", test.choice+"\n2\n2\nsearch-model\nlow\nplan-model\n\n\nhigh\n")
			if !strings.Contains(output, "creados=4; reemplazados=0; eliminados=0") ||
				!strings.Contains(output, "Clásico / Adaptive experimental") ||
				!strings.Contains(output, "Adaptive experimental · Delegar pasos Easy") ||
				!strings.Contains(readProject(t, project, search), "search-model") ||
				!strings.Contains(readProject(t, project, plan), "plan-model") {
				t.Fatal(output)
			}
			worker := readProject(t, project, easy)
			if !strings.Contains(worker, test.model) || !strings.Contains(worker, test.effort) {
				t.Fatal(worker)
			}
			previousMarker := readProject(t, project, marker)
			if test.choice == "1" {
				invoke(t, project, "", "12\n")
				if readProject(t, project, marker) != previousMarker || readProject(t, project, easy) != worker {
					t.Fatal("Zed changed Codex configuration")
				}
			}
			saveProject(t, project, search, "old profile")
			output = invoke(t, project, "", test.choice+"\n1\n\nnew-model\n\n\n\n")
			if !strings.Contains(output, "creados=0; reemplazados=3; eliminados=1") ||
				!strings.Contains(readProject(t, project, search), "new-model") {
				t.Fatal(output)
			}
			expectMissing(t, project, easy)
			output = invoke(t, project, "", test.choice+"\n1\n1\n")
			if !strings.Contains(output, "creados=0; reemplazados=0; eliminados=3") {
				t.Fatal(output)
			}
			for _, name := range []string{marker, search, plan} {
				expectMissing(t, project, name)
			}
			if readProject(t, project, extra) != "other profile" {
				t.Fatal("unrelated profile was changed")
			}
		})
	}
}

func TestExperimentalProfiles(t *testing.T) {
	for _, test := range []struct {
		choice, client, prefix, worker, model, extra string
	}{
		{"3", "GitHub Copilot", ".github", "litespec-easy.agent.md", "Claude Sonnet 4.5 (copilot)", "name: litespec-easy"},
		{"4", "Cursor", ".cursor", "litespec-easy.md", "sonnet[thinking=on,effort=medium]", "name: litespec-easy"},
		{"5", "OpenCode", ".opencode", "litespec-easy.md", "provider/model#variant", "mode: subagent"},
		{"7", "Gemini CLI", ".gemini", "litespec-easy.md", "gemini-model", "kind: local"},
		{"8", "Qwen Code", ".qwen", "litespec-easy.md", "provider/model", "name: litespec-easy"},
	} {
		t.Run(test.client, func(t *testing.T) {
			project := t.TempDir()
			worker := test.prefix + "/agents/" + test.worker
			marker := test.prefix + "/skills/litespec-shared/adaptive-active.md"
			invoke(t, project, "", test.choice+"\n2\n"+test.model+"\n")
			profile := readProject(t, project, worker)
			if !strings.Contains(profile, "model: '"+test.model+"'") || !strings.Contains(profile, test.extra) ||
				(test.client == "OpenCode" && strings.Contains(profile, "name:")) {
				t.Fatal(profile)
			}
			active := readProject(t, project, marker)
			if !strings.Contains(active, "Client: "+test.client+".") || !strings.Contains(active, worker) {
				t.Fatal(active)
			}
			invoke(t, project, "", test.choice+"\n2\n\n")
			if strings.Contains(readProject(t, project, worker), "model:") {
				t.Fatal("empty model should use the client default")
			}
			invoke(t, project, "", test.choice+"\n1\n")
			expectMissing(t, project, worker)
			expectMissing(t, project, marker)
		})
	}
}

func TestPreflightPreservesExistingFiles(t *testing.T) {
	for _, test := range []struct {
		name, input, conflict string
	}{
		{"invalid agent", "14\n", ""},
		{"invalid multi-agent selection", "1,14\n", ""},
		{"invalid mode", "1\n3\n", ""},
		{"invalid model", "5\n2\nbad model\n", ""},
		{"invalid effort", "2\n2\n1\nsonnet\nultra\n", ""},
		{"cancelled", "1\n2\n1\n", ""},
		{"profile conflict", "1\n1\n1\n", ".codex/agents/litespec-plan.toml/keep"},
		{"skill conflict", "1\n1\n1\n", ".agents/skills/litespec-verify/SKILL.md/keep"},
		{"skill conflict on second agent", "1,6\n1\n1\n", ".qoder/skills/litespec-verify/SKILL.md/keep"},
		{"data conflict", "1\n1\n1\n", ".litespec"},
	} {
		t.Run(test.name, func(t *testing.T) {
			project := t.TempDir()
			skill := ".agents/skills/litespec-explore/SKILL.md"
			saveProject(t, project, skill, "previous skill")
			if test.conflict != "" {
				saveProject(t, project, test.conflict, "preserve me")
			}
			var output bytes.Buffer
			err := run([]string{"init", "--project", project}, strings.NewReader(test.input), &output, "")
			if err == nil || readProject(t, project, skill) != "previous skill" {
				t.Fatalf("expected preflight failure without replacement: %v\n%s", err, output.String())
			}
			if test.conflict != "" && readProject(t, project, test.conflict) != "preserve me" {
				t.Fatal("conflicting file was changed")
			}
			expectMissing(t, project, installLock)
		})
	}
}

func TestRejectsDestinationLink(t *testing.T) {
	project, outside := t.TempDir(), t.TempDir()
	link := filepath.Join(project, ".agents")
	if err := os.Symlink(outside, link); err != nil {
		t.Skipf("symbolic links unavailable: %v", err)
	}
	var output bytes.Buffer
	err := run([]string{"init", "--project", project}, strings.NewReader("1\n1\n1\n"), &output, "")
	if err == nil || !strings.Contains(err.Error(), "enlaces") {
		t.Fatalf("expected a destination link error, got %v", err)
	}
	expectMissing(t, outside, "skills")
	expectMissing(t, project, ".litespec")
}

func TestGitignoreOptions(t *testing.T) {
	t.Setenv("GIT_DIR", filepath.Join(t.TempDir(), "missing"))
	for _, test := range []struct {
		name, answer string
		local        bool
		wantExe      bool
		wantSkills   bool
	}{
		{"skills only with external binary", "sí", false, false, true},
		{"skills only with local binary", "c", true, false, true},
		{"binary only", "ins", true, true, false},
		{"binary and skills", "yes", true, true, true},
		{"keep", "", true, false, false},
	} {
		t.Run(test.name, func(t *testing.T) {
			project := t.TempDir()
			executable := filepath.Join(t.TempDir(), "litespec.exe")
			if test.local {
				executable = filepath.Join(project, "lite spec[1].exe")
				saveProject(t, project, filepath.Base(executable), "downloaded")
			}
			original := "# user rule\r\n/.unrelated/\r\nlast"
			saveProject(t, project, ".gitignore", original)
			input := "1\n1\n1\n" + test.answer + "\n"
			invoke(t, project, executable, input)
			ignored := readProject(t, project, ".gitignore")
			if !strings.HasPrefix(ignored, original) || strings.Contains(strings.ReplaceAll(ignored, "\r\n", ""), "\n") ||
				strings.Contains(ignored, `/lite\ spec\[1\].exe`) != test.wantExe ||
				strings.Contains(ignored, "/.agents/skills/litespec-explore/") != test.wantSkills {
				t.Fatalf("unexpected .gitignore: %q", ignored)
			}
			invoke(t, project, executable, input)
			if readProject(t, project, ".gitignore") != ignored {
				t.Fatal("reinstall duplicated ignore rules")
			}
			if test.local && readProject(t, project, filepath.Base(executable)) != "downloaded" {
				t.Fatal("the reusable executable should be kept")
			}
		})
	}
}
