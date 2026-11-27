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
	{name: "Gemini CLI", skills: ".gemini/skills", profiles: ".gemini/agents", invocation: "through its native subagent tool", modelField: "kind: local\n", workerModel: "flash"},
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
	"GitHub Copilot": regexp.MustCompile(`^[a-zA-Z0-9][a-zA-Z0-9 ._:/()-]*$`),
	"Cursor":         regexp.MustCompile(`^[a-zA-Z0-9][a-zA-Z0-9._:/-]*(\[([a-zA-Z0-9_-]+=[a-zA-Z0-9._-]+(,[a-zA-Z0-9_-]+=[a-zA-Z0-9._-]+)*)?\])?$`),
	"OpenCode":       regexp.MustCompile(`^[a-zA-Z0-9][a-zA-Z0-9._:/-]*(#[a-zA-Z0-9][a-zA-Z0-9._-]*)?$`),
}

var roleDescriptions = map[string]string{
	"easy":     "Execute only the Easy step explicitly assigned by the LiteSpec parent.",
	"medium":   "Execute only the Medium step explicitly assigned by the LiteSpec parent.",
	"executor": "Execute only the Easy or Medium step explicitly assigned by the LiteSpec parent.",
	"search":   "Index relevant files and locate references with paths and lines; do not edit or decide scope.",
	"plan":     "Analyze available evidence and return a bounded proposal; do not edit or implement.",
	"research": "Investigate a complex technical question and return evidence, tradeoffs and uncertainties; do not edit or implement.",
}

type fileChange struct {
	name    string
	content []byte
	remove  bool
}

func writeChange(name, content string) fileChange {
	return fileChange{name: name, content: []byte(content)}
}

func (a agent) configure(root *os.Root, menu terminal) (string, []fileChange, error) {
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
	if a.invocation != "" {
		changes, err := a.experimentalChanges(menu, adaptive)
		return modeLabel, changes, err
	}

	marker := path.Join(a.skills, "litespec-shared/delegation-active.md")
	info, err := checkPath(root, marker, false, false, menu.language)
	if err != nil {
		return "", nil, err
	}
	defaultRoles := 0
	if info != nil {
		defaultRoles = 1
	}
	roleHelp := fmt.Sprintf(menu.text(
		"Auto model es para cuando el agente principal genera las specs.\nIndexación · %s   Análisis acotado · %s\nInvestigación compleja · %s\nRedacción final · %s sugerido para el principal",
		"Auto model is for when the parent agent generates the specs.\nIndexing · %s   Bounded analysis · %s\nComplex research · %s\nFinal drafting · %s suggested for the parent",
	), a.models.light, a.models.standard, a.models.advanced, a.models.advanced)
	roles, err := menu.choose(menu.text("Delegación interna de las skills", "Internal skill delegation"), roleHelp,
		fmt.Sprintf("Roles [%d]", defaultRoles+1),
		[]string{menu.text("Desactivada", "Disabled"), menu.text("Auto model por rol", "Auto model by role")},
		defaultRoles, menu.text("opción de roles inválida", "invalid role option"))
	if err != nil {
		return "", nil, err
	}
	autoModel := roles == 1
	if autoModel {
		modeLabel += " + Auto model"
	}
	changes, err := a.nativeChanges(menu, marker, autoModel, adaptive)
	return modeLabel, changes, err
}

func (a agent) nativeChanges(menu terminal, marker string, autoModel, adaptive bool) ([]fileChange, error) {
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
		enabled            bool
	}{
		{"search", menu.text("Indexación", "Indexing"), a.models.light, autoModel},
		{"plan", menu.text("Análisis acotado", "Bounded analysis"), a.models.standard, autoModel},
		{"research", menu.text("Investigación compleja", "Complex research"), a.models.advanced, autoModel},
		{"easy", menu.text("Fácil · Ejecución", "Easy · Execution"), a.models.light, adaptive},
		{"medium", menu.text("Medio · Ejecución", "Medium · Execution"), a.models.standard, adaptive},
	}
	changes := make([]fileChange, 0, len(roleModels)+2)
	// Retired by the Easy/Medium scale; removed on every reinstall.
	changes = append(changes, fileChange{name: path.Join(a.profiles, "litespec-very-easy."+extension), remove: true})
	if !autoModel {
		changes = append(changes, fileChange{name: marker, remove: true})
	}
	for _, profile := range roleModels {
		role := profile.role
		name := path.Join(a.profiles, "litespec-"+role+"."+extension)
		if !profile.enabled {
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
	if autoModel {
		content := fmt.Sprintf("Native delegation active.\nAdapter: %s. Use litespec-search, litespec-plan and litespec-research when useful under delegation.md. Native definitions: %s/litespec-{search,plan,research}.%s. Do not assume the configured model/effort is applied. On failure inform and continue with current agent within authorization.\n", a.native, a.profiles, extension)
		changes = append(changes, writeChange(marker, content))
	}
	return changes, nil
}

func (a agent) instructions(role string) string {
	if isExecutor(role) {
		return fmt.Sprintf("Follow %s/litespec-shared/executor.md for the assigned step. Do not delegate.", a.skills)
	}
	return fmt.Sprintf("%s Follow %s/litespec-shared/protocol.md. Do not delegate. Respect parent authorization and existing edits. Parent owns LiteSpec records and Archive. Return evidence, checks, uncertainty and pending work.", roleDescriptions[role], a.skills)
}

func (a agent) nativeProfile(role, model, effort string) string {
	var profile strings.Builder
	if a.native == "codex" {
		fmt.Fprintf(&profile, "name = %q\ndescription = %q\ndeveloper_instructions = %q\n", "litespec-"+role, roleDescriptions[role], a.instructions(role))
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
	if !isExecutor(role) {
		profile.WriteString("tools: Read, Grep, Glob\n")
	}
	fmt.Fprintf(&profile, "---\n\n%s\n", a.instructions(role))
	return profile.String()
}

func (a agent) experimentalChanges(menu terminal, adaptive bool) ([]fileChange, error) {
	workerFile := a.workerFile
	if workerFile == "" {
		workerFile = "litespec-executor.md"
	}
	worker := path.Join(a.profiles, workerFile)
	// The single worker was named litespec-easy before the Easy/Medium scale.
	retired := fileChange{name: path.Join(a.profiles, strings.Replace(workerFile, "litespec-executor", "litespec-easy", 1)), remove: true}
	marker := path.Join(a.skills, "litespec-shared/adaptive-active.md")
	if !adaptive {
		return []fileChange{retired, {name: marker, remove: true}, {name: worker, remove: true}}, nil
	}

	if a.name == "GitHub Copilot" {
		fmt.Fprintln(menu.out, menu.text(
			"VS Code usa el nombre visible del modelo. Copilot CLI usa su identificador.",
			"VS Code uses the model's display name. Copilot CLI uses its identifier.",
		))
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
	fmt.Fprintf(&profile, "---\n\n%s\n", a.instructions("executor"))
	active := fmt.Sprintf("Adaptive active.\nClient: %s. Executor: %s. Only %s uses this marker; any other client ignores it and the Adaptive rules. Invoke the litespec-executor subagent %s for easy and medium steps. Do not assume the requested model is applied; if the worker is unavailable, follow adaptive-apply.md.\n", a.name, worker, a.name, a.invocation)
	return []fileChange{retired, writeChange(worker, profile.String()), writeChange(marker, active)}, nil
}

func isExecutor(role string) bool {
	return role == "easy" || role == "medium" || role == "executor"
}
