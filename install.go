package main

import (
	"bytes"
	"crypto/rand"
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path"
	"path/filepath"
	"runtime"
	"slices"
	"strings"
	"syscall"
)

const sourceTree = "lite.spec.steps"
const installLock = ".litespec-install.lock"

func installedSkillDestinations(root *os.Root) []string {
	files, _ := fs.Glob(packageFiles, sourceTree+"/*/*.md")
	var installed []string
	checked := make(map[string]bool)
	for _, agent := range agents {
		if checked[agent.skills] {
			continue
		}
		checked[agent.skills] = true
		if info, _ := checkPath(root, agent.skills, true, false, spanish); info == nil {
			continue
		}
		for _, name := range files {
			target := path.Join(agent.skills, strings.TrimPrefix(name, sourceTree+"/"))
			if info, _ := checkPath(root, target, false, false, spanish); info != nil {
				installed = append(installed, agent.skills+"/")
				break
			}
		}
	}
	return installed
}

func install(root *os.Root, menu terminal, agent agent, executable string) (err error) {
	skills, folders, err := skillChanges(agent.skills)
	if err != nil {
		return err
	}
	mode, profiles, err := agent.configure(root, menu)
	if err != nil {
		return err
	}
	ignoreEntries, err := askGitignore(root, menu, folders, executable)
	if err != nil {
		return err
	}

	if err := root.Mkdir(installLock, 0o755); err != nil {
		if errors.Is(err, fs.ErrExist) {
			return fmt.Errorf(menu.text(
				"existe %s en el proyecto. Si se interrumpió una instalación, quitá esa carpeta vacía cuando ya no haya otro instalador en ejecución",
				"%s already exists in the project. If an installation was interrupted, remove that empty folder once no other installer is running",
			), installLock)
		}
		return err
	}
	defer func() { err = errors.Join(err, root.Remove(installLock)) }()

	// Check every destination before replacing any installed file.
	if _, err := checkPath(root, ".litespec", true, false, menu.language); err != nil {
		return err
	}
	for _, change := range append(slices.Clone(skills), profiles...) {
		if _, err := checkPath(root, change.name, false, change.remove, menu.language); err != nil {
			return err
		}
	}
	if err := root.MkdirAll(".litespec", 0o755); err != nil {
		return err
	}
	for _, change := range skills {
		if _, err := applyChange(root, change, menu.language); err != nil {
			return err
		}
	}
	var created, replaced, removed int
	for _, change := range profiles {
		existed, err := applyChange(root, change, menu.language)
		if err != nil {
			return err
		}
		switch {
		case change.remove && existed:
			removed++
		case !change.remove && existed:
			replaced++
		case !change.remove:
			created++
		}
	}
	if len(ignoreEntries) > 0 {
		count, err := updateGitignore(root, ignoreEntries, menu.language)
		if err != nil {
			return fmt.Errorf(menu.text(
				"skills instaladas, pero falló la actualización de .gitignore: %w",
				"skills installed, but .gitignore could not be updated: %w",
			), err)
		}
		fmt.Fprintf(menu.out, menu.text(".gitignore: %d reglas añadidas.\n", ".gitignore: %d rules added.\n"), count)
	}

	fmt.Fprintf(menu.out, menu.text("Agente: %s | Modo: %s\n", "Agent: %s | Mode: %s\n"), agent.name, mode)
	menu.status("✓", "#64C49D", fmt.Sprintf(menu.text("Skills copiadas y verificadas en %s.", "Skills copied and verified in %s."), filepath.Join(root.Name(), agent.skills)))
	fmt.Fprintf(menu.out, menu.text(
		"Archivos de configuración: creados=%d; reemplazados=%d; eliminados=%d.\n",
		"Configuration files: created=%d; replaced=%d; removed=%d.\n",
	), created, replaced, removed)
	if agent.name == "Zed" {
		fmt.Fprintln(menu.out, menu.text("Zed usa el flujo normal y conserva la configuración de Codex.", "Zed uses the standard workflow and preserves the Codex configuration."))
	}
	if mode != menu.text("Clásico", "Classic") {
		fmt.Fprintf(menu.out, menu.text(
			"Configuración: %s. Confirmá en el cliente que se cargaron los modelos.\n",
			"Configuration: %s. Check in your client that the models loaded.\n",
		), filepath.Join(root.Name(), agent.profiles))
	}
	fmt.Fprintln(menu.out, menu.text("Abrí una nueva sesión del agente para aplicar el modo.", "Start a new agent session to apply the selected mode."))
	return nil
}

func skillChanges(destination string) ([]fileChange, []string, error) {
	var changes []fileChange
	var folders []string
	err := fs.WalkDir(packageFiles, sourceTree, func(name string, entry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if name == sourceTree {
			return nil
		}
		target := path.Join(destination, strings.TrimPrefix(name, sourceTree+"/"))
		if entry.IsDir() {
			folders = append(folders, target+"/")
			return nil
		}
		data, err := packageFiles.ReadFile(name)
		if err == nil {
			changes = append(changes, fileChange{name: target, content: data})
		}
		return err
	})
	return changes, folders, err
}

// Walk each component so existing links (including Windows junctions) are
// rejected even if their targets are inside the project.
func checkPath(root *os.Root, name string, directory, removing bool, lang language) (fs.FileInfo, error) {
	current := ""
	for part := range strings.SplitSeq(name, "/") {
		current = path.Join(current, part)
		info, err := root.Lstat(current)
		if errors.Is(err, fs.ErrNotExist) {
			return nil, nil
		}
		if err != nil {
			return nil, err
		}
		if info.Mode()&(fs.ModeSymlink|fs.ModeIrregular) != 0 {
			return nil, fmt.Errorf(lang.text("no se admiten enlaces o junctions: %s", "links and junctions are unsupported: %s"), current)
		}
		if current != name || directory {
			if !info.IsDir() {
				if removing && current != name {
					return nil, nil
				}
				return nil, fmt.Errorf(lang.text("se esperaba una carpeta en %s", "expected a directory at %s"), current)
			}
		} else if !info.Mode().IsRegular() {
			return nil, fmt.Errorf(lang.text("se esperaba un archivo en %s", "expected a file at %s"), current)
		}
		if current == name {
			return info, nil
		}
	}
	return nil, fmt.Errorf(lang.text("ruta inválida: %q", "invalid path: %q"), name)
}

func applyChange(root *os.Root, change fileChange, lang language) (bool, error) {
	info, err := checkPath(root, change.name, false, change.remove, lang)
	if err != nil {
		return false, err
	}
	existed := info != nil
	if change.remove {
		if existed {
			return true, root.Remove(change.name)
		}
		return false, nil
	}
	if err := root.MkdirAll(path.Dir(change.name), 0o755); err != nil {
		return false, err
	}
	return existed, replaceFile(root, change.name, change.content, nil, lang)
}

// Prepare the complete replacement alongside its destination before renaming.
func replaceFile(root *os.Root, name string, data []byte, preserve fs.FileInfo, lang language) error {
	directory, err := root.OpenRoot(path.Dir(name))
	if err != nil {
		return err
	}
	defer directory.Close()
	name = path.Base(name)
	temporary := ".litespec-" + rand.Text() + ".tmp"
	file, err := directory.OpenFile(temporary, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0o666)
	if err != nil {
		return err
	}
	defer directory.Remove(temporary)
	_, writeErr := file.Write(data)
	if preserve != nil && writeErr == nil {
		writeErr = file.Chmod(preserve.Mode().Perm())
	}
	if err := errors.Join(writeErr, file.Close()); err != nil {
		return err
	}
	if err := renameInDirectory(directory, temporary, name); err != nil {
		return err
	}
	actual, err := directory.ReadFile(name)
	if err != nil {
		return err
	}
	if !bytes.Equal(actual, data) {
		return fmt.Errorf(lang.text("falló la verificación de %s", "verification failed for %s"), name)
	}
	return nil
}

func renameInDirectory(directory *os.Root, from, to string) error {
	err := directory.Rename(from, to)
	const invalidWindowsHandle = syscall.Errno(6)
	if runtime.GOOS != "windows" || !errors.Is(err, invalidWindowsHandle) {
		return err
	}
	// Some Windows sandboxes reject the handle-relative rename. Keep the
	// directory open (without delete sharing) and verify the named directory
	// before retrying the same-directory replacement through Win32.
	held, heldErr := directory.Stat(".")
	named, namedErr := os.Stat(directory.Name())
	if heldErr != nil || namedErr != nil || !os.SameFile(held, named) {
		return err
	}
	return os.Rename(filepath.Join(directory.Name(), from), filepath.Join(directory.Name(), to))
}
