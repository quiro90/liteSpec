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
	name       string
	skills     string
	profiles   string
	native     string
	easyFile   string
	invocation string
	modelField string
	easyModel  string
}

var agents = []agent{
	{name: "Codex", skills: ".agents/skills", profiles: ".codex/agents", native: "codex"},
	{name: "Claude Code", skills: ".claude/skills", profiles: ".claude/agents", native: "claude"},
	{
		name: "GitHub Copilot", skills: ".github/skills", profiles: ".github/agents", easyFile: "litespec-easy.agent.md",
		invocation: "through the native subagent or custom-agent delegation of the current surface (VS Code, Copilot CLI or other)",
	},
	{name: "Cursor", skills: ".cursor/skills", profiles: ".cursor/agents", invocation: "through native subagent delegation"},
	{name: "OpenCode", skills: ".opencode/skills", profiles: ".opencode/agents", invocation: "through native subagent delegation", modelField: "mode: subagent\n"},
	{name: "Qoder CLI", skills: ".qoder/skills"},
	{name: "Gemini CLI", skills: ".gemini/skills", profiles: ".gemini/agents", invocation: "through its native subagent tool", modelField: "kind: local\n", easyModel: "flash"},
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
	"easy":   "Execute only the Easy step explicitly assigned by the LiteSpec parent.",
	"search": "Gather concrete evidence with paths and lines; do not edit or decide scope.",
	"plan":   "Analyze evidence and return a proposal; do not edit or implement.",
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
	mode, err := menu.choose(menu.text("Ejecución de pasos", "Step execution"), menu.text("Modo [1]", "Mode [1]"),
		[]string{classic, modeLabel + menu.text(" · Delegar pasos Easy", " · Delegate Easy steps")}, 0,
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
	roles, err := menu.choose(menu.text("Delegación interna de las skills", "Internal skill delegation"),
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
		role, codex, claude string
	}{
		{"search", "gpt-6-luna", "haiku"},
		{"plan", "gpt-6.2-astra", "sonnet"},
		{"easy", "gpt-6.2-sol", "sonnet"},
	}
	changes := make([]fileChange, 0, 4)
	if !autoModel {
		changes = append(changes, fileChange{name: marker, remove: true})
	}
	for _, defaults := range roleModels {
		role := defaults.role
		if role == "easy" && autoModel {
			content := fmt.Sprintf("Native delegation active.\nAdapter: %s. Use litespec-search and litespec-plan when useful under delegation.md. Native definitions: %s/litespec-{search,plan}.%s. Do not assume the configured model/effort is applied. On failure inform and continue with current agent within authorization.\n", a.native, a.profiles, extension)
			changes = append(changes, writeChange(marker, content))
		}
		name := path.Join(a.profiles, "litespec-"+role+"."+extension)
		enabled := autoModel
		if role == "easy" {
			enabled = adaptive
		}
		if !enabled {
			changes = append(changes, fileChange{name: name, remove: true})
			continue
		}

		modelDefault := defaults.claude
		if codex {
			modelDefault = defaults.codex
		}
		model, err := menu.ask(fmt.Sprintf(menu.text("%s - modelo [predeterminado: %s]", "%s - model [default: %s]"), role, modelDefault))
		if err != nil {
			return nil, err
		}
		if model == "" {
			model = modelDefault
		}
		if !modelPattern.MatchString(model) {
			return nil, errors.New(menu.text("identificador de modelo inválido", "invalid model identifier"))
		}
		if codex && strings.EqualFold(model, "inherit") {
			model = ""
		}

		effort, err := menu.ask(fmt.Sprintf(menu.text("%s - esfuerzo opcional [predeterminado: %s]", "%s - optional effort [default: %s]"), role, defaultEffort))
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

func (a agent) instructions(role string) string {
	if role == "easy" {
		return fmt.Sprintf("Follow %s/litespec-shared/easy-worker.md for the assigned step. Do not delegate.", a.skills)
	}
	return fmt.Sprintf("%s Read applicable AGENTS.md and %s/litespec-shared/protocol.md. Do not delegate. Respect parent authorization and existing edits. Parent owns LiteSpec records and Archive. Return evidence, checks, uncertainty and pending work.", roleDescriptions[role], a.skills)
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
	if role != "easy" {
		profile.WriteString("tools: Read, Grep, Glob\n")
	}
	fmt.Fprintf(&profile, "---\n\n%s\n", a.instructions(role))
	return profile.String()
}

func (a agent) experimentalChanges(menu terminal, adaptive bool) ([]fileChange, error) {
	easyFile := a.easyFile
	if easyFile == "" {
		easyFile = "litespec-easy.md"
	}
	worker := path.Join(a.profiles, easyFile)
	marker := path.Join(a.skills, "litespec-shared/adaptive-active.md")
	if !adaptive {
		return []fileChange{{name: marker, remove: true}, {name: worker, remove: true}}, nil
	}

	if a.name == "GitHub Copilot" {
		fmt.Fprintln(menu.out, menu.text(
			"VS Code usa el nombre visible del modelo. Copilot CLI usa su identificador.",
			"VS Code uses the model's display name. Copilot CLI uses its identifier.",
		))
	}
	prompt := menu.text("easy - modelo [vacío = predeterminado del cliente]", "easy - model [blank = client default]")
	if a.easyModel != "" {
		prompt = fmt.Sprintf(menu.text("easy - modelo [predeterminado: %s]", "easy - model [default: %s]"), a.easyModel)
	}
	model, err := menu.ask(prompt)
	if err != nil {
		return nil, err
	}
	if model == "" {
		model = a.easyModel
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
		profile.WriteString("name: litespec-easy\n")
	}
	fmt.Fprintf(&profile, "description: %s\n%s", roleDescriptions["easy"], a.modelField)
	if model != "" {
		fmt.Fprintf(&profile, "model: '%s'\n", model)
	}
	fmt.Fprintf(&profile, "---\n\n%s\n", a.instructions("easy"))
	active := fmt.Sprintf("Adaptive active.\nClient: %s. Easy worker: %s. Only %s uses this marker; any other client ignores it and the Adaptive rules. Invoke the litespec-easy subagent %s. Do not assume the requested model is applied; if the worker is unavailable, follow adaptive-apply.md.\n", a.name, worker, a.name, a.invocation)
	return []fileChange{writeChange(worker, profile.String()), writeChange(marker, active)}, nil
}
