package main

import (
	"errors"
	"fmt"
	"os"
	"path"
	"regexp"
	"slices"
	"strings"
)

type agent struct {
	name        string
	skills      string
	profiles    string
	native      string
	workerFile  string
	invocation  string
	modelField  string
	workerModel string
	models      nativeModels
}

type nativeModels struct {
	light, standard, advanced string
}

var agents = []agent{
	{
		name: "Codex", skills: ".agents/skills", profiles: ".codex/agents", native: "codex",
		models: nativeModels{light: "gpt-6-luna", standard: "gpt-6.2-sol", advanced: "gpt-6.2-astra"},
	},
	{
		name: "Claude Code", skills: ".claude/skills", profiles: ".claude/agents", native: "claude",
		models: nativeModels{light: "haiku", standard: "sonnet", advanced: "opus"},
	},
	{
		name: "GitHub Copilot", skills: ".github/skills", profiles: ".github/agents", workerFile: "litespec-executor.agent.md",
		invocation: "through the native subagent or custom-agent delegation of the current surface (VS Code, Copilot CLI or other)",
	},
	{name: "Cursor", skills: ".cursor/skills", profiles: ".cursor/agents", invocation: "through native subagent delegation", workerModel: "composer-2.5[]"},
	{name: "OpenCode", skills: ".opencode/skills", profiles: ".opencode/agents", invocation: "through native subagent delegation", modelField: "mode: subagent\n", workerModel: "anthropic/claude-haiku-4-5"},
	{name: "Qoder CLI", skills: ".qoder/skills"},
	{name: "Gemini CLI", skills: ".gemini/skills", profiles: ".gemini/agents", invocation: "through its native subagent tool", modelField: "kind: local\n", workerModel: "gemini-4-hydrogen"},
	{name: "Antigravity", skills: ".agents/skills", profiles: ".agents/agents", invocation: "with invoke_subagent", modelField: "mainAgent: false\nsubagent: true\n", workerModel: "flash"},
	{name: "Qwen Code", skills: ".qwen/skills", profiles: ".qwen/agents", invocation: "through native subagent delegation"},
	{name: "Cline", skills: ".cline/skills"},
	{name: "Devin Local", skills: ".devin/skills"},
	{name: "ADE", skills: ".ade/skills"},
	{name: "Zed", skills: ".agents/skills"},
	{name: "MiniMax Code", skills: ".minimax/skills"},
}

var modelID = regexp.MustCompile(`^[a-zA-Z0-9][a-zA-Z0-9._:/-]*$`)
var claudeModelID = regexp.MustCompile(`^[a-zA-Z0-9][a-zA-Z0-9._:/@-]*(\[1m\])?$`)
var experimentalModelIDs = map[string]*regexp.Regexp{
	"Antigravity":    regexp.MustCompile(`^(flash|pro|inherit)$`),
	"GitHub Copilot": regexp.MustCompile(`^[a-zA-Z0-9][a-zA-Z0-9 ._:/()-]*$`),
	"Cursor":         regexp.MustCompile(`^[a-zA-Z0-9][a-zA-Z0-9._:/-]*(\[([a-zA-Z0-9_-]+=[a-zA-Z0-9._-]+(,[a-zA-Z0-9_-]+=[a-zA-Z0-9._-]+)*)?\])?$`),
	"OpenCode":       regexp.MustCompile(`^[a-zA-Z0-9][a-zA-Z0-9._:/-]*(#[a-zA-Z0-9][a-zA-Z0-9._-]*)?$`),
}

var roleDescriptions = map[string]string{
	"easy":     "Execute only the Easy step explicitly assigned by the LiteSpec parent.",
	"medium":   "Execute only the Medium step explicitly assigned by the LiteSpec parent.",
	"executor": "Execute only the Easy or Medium step explicitly assigned by the LiteSpec parent.",
}

type fileChange struct {
	name    string
	content []byte
	remove  bool
}

func writeChange(name, content string) fileChange {
	return fileChange{name: name, content: []byte(content)}
}

func (a agent) configure(root *os.Root, menu terminal, delegation map[string]bool, selected []agent) (string, []fileChange, error) {
	classic := menu.text("Clásico", "Classic")
	if a.profiles == "" {
		return classic, nil, nil
	}
	modeLabel := menu.text("Adaptive experimental", "Experimental Adaptive")
	adaptiveHelp := menu.text(
		"Fácil (easy): cambio mecánico. Medio (medium): lógica definida y comprobable.\nDifícil (hard): el principal resuelve una decisión pendiente.",
		"Easy: mechanical work. Medium: defined logic with a check.\nHard: the parent resolves an open decision.",
	)
	delegateLabel := menu.text(" · Delegar pasos fáciles y medios", " · Delegate Easy and Medium steps")
	switch {
	case a.native != "":
		adaptiveHelp += fmt.Sprintf(menu.text(
			"\nEjecutores · Fácil %s / Medio %s\nPrincipal sugerido · Difícil %s",
			"\nWorkers · Easy %s / Medium %s\nSuggested parent · Hard %s",
		), a.models.light, a.models.standard, a.models.advanced)
	case a.workerModel != "":
		adaptiveHelp += fmt.Sprintf(menu.text("\nFácil y medio · Modelo predeterminado %s", "\nEasy and Medium · Default model %s"), a.workerModel)
	}
	mode, err := menu.choose(menu.text("Ejecución de pasos", "Step execution"), adaptiveHelp, menu.text("Modo [1]", "Mode [1]"),
		[]string{classic, modeLabel + delegateLabel}, 0,
		menu.text("modo inválido", "invalid mode"))
	if err != nil {
		return "", nil, err
	}
	adaptive := mode == 1
	if !adaptive {
		modeLabel = classic
	}
	enabled, decided := delegation[a.skills]
	if !decided {
		enabled, err = configureDelegation(root, menu, a, selected)
		if err != nil {
			return "", nil, err
		}
		delegation[a.skills] = enabled
	}
	if enabled {
		modeLabel += menu.text(" + Delegación", " + Delegation")
	}
	var profiles []fileChange
	if a.native != "" {
		profiles, err = a.nativeChanges(menu, adaptive)
	} else {
		profiles, err = a.experimentalChanges(menu, adaptive)
	}
	return modeLabel, profiles, err
}

const delegationRule = "litespec-shared/delegation.md"
const legacyDelegationMarker = "litespec-shared/delegation-active.md"

// installedDelegation reports the setting already present in a skills destination.
func installedDelegation(root *os.Root, menu terminal, destination string) (bool, error) {
	old, err := checkPath(root, path.Join(destination, legacyDelegationMarker), false, false, menu.language)
	if err != nil || old != nil {
		return old != nil, err
	}
	name := path.Join(destination, delegationRule)
	info, err := checkPath(root, name, false, false, menu.language)
	if err != nil || info == nil {
		return false, err
	}
	content, err := root.ReadFile(name)
	if err != nil {
		return false, err
	}
	// Older releases installed this document even with AutoMode disabled.
	return !strings.HasPrefix(string(content), "# Native delegation"), nil
}

// supportsDelegation reports whether a client offering Delegation installs into destination.
func supportsDelegation(destination string) bool {
	return slices.ContainsFunc(agents, func(a agent) bool { return a.profiles != "" && a.skills == destination })
}

// delegationDefault keeps the existing setting only where a Delegation client owns the folder.
func delegationDefault(root *os.Root, menu terminal, destination string) (bool, error) {
	if !supportsDelegation(destination) {
		return false, nil
	}
	return installedDelegation(root, menu, destination)
}

func configureDelegation(root *os.Root, menu terminal, current agent, selected []agent) (bool, error) {
	enabled, err := delegationDefault(root, menu, current.skills)
	if err != nil {
		return false, err
	}
	def := 0
	if enabled {
		def = 1
	}
	help := menu.text("Búsquedas de solo lectura en Explore, Propose y Modify. El principal decide el alcance y el diseño.", "Read-only lookups during Explore, Propose and Modify. The parent decides scope and design.")
	help += sharedDelegationNotice(menu, current, selected)
	label := menu.text("Delegación", "Delegation")
	choice, err := menu.choose(label, help, fmt.Sprintf("%s [%d]", label, def+1), []string{
		menu.text("Desactivada", "Disabled"), menu.text("Permitir búsquedas con subagentes", "Allow subagent lookups"),
	}, def, menu.text("opción de delegación inválida", "invalid delegation option"))
	return choice == 1, err
}

// sharedDelegationNotice names the clients affected by a choice made for a shared skills folder.
func sharedDelegationNotice(menu terminal, current agent, selected []agent) string {
	var sharing, alsoSelected []string
	for _, other := range agents {
		if other.skills != current.skills {
			continue
		}
		sharing = append(sharing, other.name)
		if other.name != current.name && slices.ContainsFunc(selected, func(s agent) bool { return s.name == other.name }) {
			alsoSelected = append(alsoSelected, other.name)
		}
	}
	if len(sharing) < 2 {
		return ""
	}
	notice := fmt.Sprintf(menu.text(
		"\n%s comparten %s/: esta elección aplica a todos.",
		"\n%s share %s/: this choice applies to all of them.",
	), joinNames(menu, sharing), current.skills)
	if len(alsoSelected) > 0 {
		notice += fmt.Sprintf(menu.text(
			"\n%s, también seleccionado, usará la misma elección.",
			"\n%s, also selected, will use the same choice.",
		), joinNames(menu, alsoSelected))
	}
	return notice
}

func joinNames(menu terminal, names []string) string {
	if len(names) < 2 {
		return strings.Join(names, "")
	}
	return strings.Join(names[:len(names)-1], ", ") + menu.text(" y ", " and ") + names[len(names)-1]
}

// delegationChanges installs or removes the shared rule and retires the AutoMode marker.
func delegationChanges(destination string, enabled bool) ([]fileChange, error) {
	rule := fileChange{name: path.Join(destination, delegationRule), remove: !enabled}
	if enabled {
		var err error
		if rule.content, err = packageFiles.ReadFile(path.Join(sourceTree, delegationRule)); err != nil {
			return nil, err
		}
	}
	return []fileChange{rule, {name: path.Join(destination, legacyDelegationMarker), remove: true}}, nil
}

func (a agent) nativeChanges(menu terminal, adaptive bool) ([]fileChange, error) {
	codex := a.native == "codex"
	extension, modelPattern := "md", claudeModelID
	allowedEfforts := []string{"low", "medium", "high", "xhigh", "max"}
	if codex {
		extension, modelPattern = "toml", modelID
		allowedEfforts = append(allowedEfforts, "none", "minimal", "ultra")
	}
	const defaultEffort = "medium"
	roleModels := [...]struct {
		role, label, model string
	}{
		{"easy", menu.text("Fácil · Ejecución", "Easy · Execution"), a.models.light},
		{"medium", menu.text("Medio · Ejecución", "Medium · Execution"), a.models.standard},
	}
	var changes []fileChange
	for _, retired := range []string{"very-easy", "search", "plan", "research"} {
		changes = append(changes, fileChange{name: path.Join(a.profiles, "litespec-"+retired+"."+extension), remove: true})
	}
	for _, profile := range roleModels {
		role := profile.role
		name := path.Join(a.profiles, "litespec-"+role+"."+extension)
		if !adaptive {
			changes = append(changes, fileChange{name: name, remove: true})
			continue
		}

		model, err := menu.askModel(profile.label+menu.text(" - modelo", " - model"), profile.model)
		if err != nil {
			return nil, err
		}
		if !modelPattern.MatchString(model) {
			return nil, errors.New(menu.text("identificador de modelo inválido", "invalid model identifier"))
		}
		if codex && strings.EqualFold(model, "inherit") {
			model = ""
		}

		effort, err := menu.ask(fmt.Sprintf(menu.text("%s - esfuerzo opcional [Enter = %s]", "%s - optional effort [Enter = %s]"), profile.label, defaultEffort))
		if err != nil {
			return nil, err
		}
		effort = strings.ToLower(effort)
		if effort == "" {
			effort = defaultEffort
		}
		if effort == "inherit" {
			effort = ""
		} else if !slices.Contains(allowedEfforts, effort) {
			return nil, errors.New(menu.text("esfuerzo inválido. La compatibilidad depende del modelo y cliente", "invalid effort. Compatibility depends on the model and client"))
		}
		changes = append(changes, writeChange(name, a.nativeProfile(role, model, effort)))
	}
	return changes, nil
}

func (a agent) executorInstructions() string {
	return fmt.Sprintf("Follow %s/litespec-shared/executor.md for the assigned step. Do not delegate.", a.skills)
}

func (a agent) nativeProfile(role, model, effort string) string {
	var profile strings.Builder
	if a.native == "codex" {
		fmt.Fprintf(&profile, "name = %q\ndescription = %q\ndeveloper_instructions = %q\n", "litespec-"+role, roleDescriptions[role], a.executorInstructions())
		if model != "" {
			fmt.Fprintf(&profile, "model = %q\n", model)
		}
		if effort != "" {
			fmt.Fprintf(&profile, "model_reasoning_effort = %q\n", effort)
		}
		return profile.String()
	}

	fmt.Fprintf(&profile, "---\nname: litespec-%s\ndescription: %s\n", role, roleDescriptions[role])
	if model != "" {
		fmt.Fprintf(&profile, "model: '%s'\n", model)
	}
	if effort != "" {
		fmt.Fprintf(&profile, "effort: %s\n", effort)
	}
	fmt.Fprintf(&profile, "---\n\n%s\n", a.executorInstructions())
	return profile.String()
}

func (a agent) experimentalChanges(menu terminal, adaptive bool) ([]fileChange, error) {
	workerFile := a.workerFile
	if workerFile == "" {
		workerFile = "litespec-executor.md"
	}
	worker := path.Join(a.profiles, workerFile)
	// The single worker was named litespec-easy before the Easy/Medium scale.
	var changes []fileChange
	if a.name != "Antigravity" {
		changes = append(changes, fileChange{name: path.Join(a.profiles, strings.Replace(workerFile, "litespec-executor", "litespec-easy", 1)), remove: true})
	}
	marker := path.Join(a.skills, "litespec-shared/adaptive-active.md")
	if !adaptive {
		return append(changes, fileChange{name: marker, remove: true}, fileChange{name: worker, remove: true}), nil
	}

	if a.name == "GitHub Copilot" {
		fmt.Fprintln(menu.out, menu.text(
			"VS Code usa el nombre visible del modelo. Copilot CLI usa su identificador.",
			"VS Code uses the model's display name. Copilot CLI uses its identifier.",
		))
	}
	if a.name == "Antigravity" {
		fmt.Fprintln(menu.out, menu.text("Categorías: flash, pro, inherit. Para usar Hydrogen, seleccionalo en la sesión y elegí inherit.", "Tiers: flash, pro, inherit. To use Hydrogen, select it in the session and choose inherit."))
	}
	model, err := menu.askModel(menu.text("Fácil y medio - modelo compartido", "Easy and Medium - shared model"), a.workerModel)
	if err != nil {
		return nil, err
	}
	if strings.EqualFold(model, "inherit") && a.name == "OpenCode" {
		model = ""
	}
	pattern := experimentalModelIDs[a.name]
	if pattern == nil {
		pattern = modelID
	}
	if model != "" && !pattern.MatchString(model) {
		return nil, errors.New(menu.text("identificador de modelo inválido", "invalid model identifier"))
	}

	var profile strings.Builder
	profile.WriteString("---\n")
	if a.name != "OpenCode" {
		profile.WriteString("name: litespec-executor\n")
	}
	fmt.Fprintf(&profile, "description: %s\n%s", roleDescriptions["executor"], a.modelField)
	if model != "" {
		fmt.Fprintf(&profile, "model: '%s'\n", model)
	}
	fmt.Fprintf(&profile, "---\n\n%s\n", a.executorInstructions())
	active := fmt.Sprintf("Adaptive active.\nClient: %s. Executor: %s. Only %s uses this marker; any other client ignores it and the Adaptive rules. Invoke the litespec-executor subagent %s for easy and medium steps. Do not assume the requested model is applied; if the worker is unavailable, follow adaptive-apply.md.\n", a.name, worker, a.name, a.invocation)
	return append(changes, writeChange(worker, profile.String()), writeChange(marker, active)), nil
}
