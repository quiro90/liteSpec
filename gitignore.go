package main

import (
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

func askGitignore(root *os.Root, menu terminal, folders []string, executable string) ([]string, error) {
	info, err := root.Lstat(".gitignore")
	if errors.Is(err, fs.ErrNotExist) || (err == nil && info.IsDir()) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	if _, err := checkPath(root, ".gitignore", false, false, menu.language); err != nil {
		return nil, err
	}

	executableName := ""
	if resolved, err := filepath.EvalSymlinks(executable); err == nil {
		if relative, err := filepath.Rel(root.Name(), resolved); err == nil &&
			filepath.IsLocal(relative) && filepath.Base(relative) == relative &&
			!strings.ContainsAny(relative, "\r\n") {
			executableName = relative
		}
	}
	leave := menu.text("Conservar como está", "Leave unchanged")
	options := []string{leave, menu.text("Excluir las skills de LiteSpec", "Ignore LiteSpec skills")}
	prompt := menu.text(
		"¿Añadir las carpetas de LiteSpec a .gitignore? [s/si/y/yes, Enter conserva]",
		"Add the LiteSpec folders to .gitignore? [y/yes, Enter keeps unchanged]",
	)
	if executableName != "" {
		options = []string{leave, menu.text("Excluir el ejecutable y las skills", "Ignore the executable and skills"), menu.text("Excluir solo el ejecutable", "Ignore only the executable")}
		prompt = menu.text(
			"¿Qué añadir a .gitignore? [s/si/y/yes] Ejecutable y skills | [i/ins] Solo ejecutable | [Enter] Conservar",
			"What should .gitignore exclude? [y/yes] Executable and skills | [i/ins] Executable only | [Enter] Leave unchanged",
		)
	}
	var choice int
	if menu.interactive {
		var err error
		choice, err = menu.choose(menu.text("Actualizar .gitignore", "Update .gitignore"), "", options, 0, "")
		if err != nil {
			return nil, err
		}
	} else {
		answer, err := menu.ask(prompt)
		if err != nil && !errors.Is(err, io.EOF) {
			return nil, err
		}
		switch strings.ToLower(answer) {
		case "s", "si", "sí", "y", "yes":
			choice = 1
		case "i", "ins":
			choice = 2
		}
	}
	switch choice {
	case 1:
		if executableName != "" {
			return append([]string{executableName}, folders...), nil
		}
		return folders, nil
	case 2:
		if executableName != "" {
			return []string{executableName}, nil
		}
	}
	return nil, nil
}

var gitignoreEscapes = strings.NewReplacer("\\", "\\\\", "*", "\\*", "?", "\\?", "[", "\\[", "]", "\\]", " ", "\\ ")

func updateGitignore(root *os.Root, entries []string, lang language) (int, error) {
	info, err := checkPath(root, ".gitignore", false, false, lang)
	if err != nil || info == nil {
		return 0, err
	}
	data, err := root.ReadFile(".gitignore")
	if err != nil {
		return 0, err
	}
	original := string(data)
	newline := "\n"
	if strings.Contains(original, "\r\n") {
		newline = "\r\n"
	}

	var additions []string
	for _, entry := range entries {
		rule := gitignoreEscapes.Replace(entry)
		if !alreadyIgnored(root.Name(), entry, rule, original) {
			additions = append(additions, "/"+rule)
		}
	}
	if len(additions) == 0 {
		return 0, nil
	}
	if original != "" && !strings.HasSuffix(original, "\n") {
		original += newline
	}
	updated := original + strings.Join(additions, newline) + newline
	if err := replaceFile(root, ".gitignore", []byte(updated), info, lang); err != nil {
		return 0, fmt.Errorf(lang.text("no se pudieron agregar las exclusiones: %w", "could not add the exclusions: %w"), err)
	}
	return len(additions), nil
}

func alreadyIgnored(project, entry, escaped, existing string) bool {
	err := exec.Command("git", "-C", project, "check-ignore", "--no-index", "-q", "--", entry).Run()
	if err == nil {
		return true
	}
	var exit *exec.ExitError
	if errors.As(err, &exit) && exit.ExitCode() == 1 {
		return false
	}

	// When Git or a repository is unavailable, honor literal rules and parents.
	ignored := false
	for line := range strings.SplitSeq(strings.TrimPrefix(existing, "\uFEFF"), "\n") {
		line = strings.TrimSuffix(line, "\r")
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		negated := strings.HasPrefix(line, "!")
		rule := strings.Trim(strings.TrimPrefix(line, "!"), "/")
		if rule != "" && (strings.TrimSuffix(escaped, "/") == rule || strings.HasPrefix(escaped, rule+"/")) {
			ignored = !negated
		}
	}
	return ignored
}
