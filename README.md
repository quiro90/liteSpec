# LiteSpec

English | [Español](README.ES.md)

Short, clear specifications for working with AI agents while keeping token usage low. LiteSpec breaks work into small steps with enough context to execute and verify each one, without loading the entire project on every read.

Generated documentation follows the same goal: minimal, organized by topic, and useful for continuing work without reconstructing conversations.

> **Experimental.** LiteSpec as a whole is experimental: the workflow, Adaptive, role delegation and installer may change between versions and have not been validated in every client. Review the specs, changes and checks an agent produces before relying on them.

## Build and publish

### Prerequisites

- Go 1.25 or later to build from source.
- PowerShell 7.3 or later (`pwsh`) to create distribution packages.

### Build for your system

Run these checks from the repository root.

```text
go test ./...
go vet ./...
```

On Windows, run `go build -o litespec.exe .`. On macOS and Linux, run `go build -o litespec .`.

A direct `go build` reports the version as `dev`. The packaging script embeds the version supplied through `-Version`. GitHub Actions supplies the release tag.

The build embeds these paths from `lite.spec.steps/` using `go:embed`.

- `lite.spec.steps/litespec-*/SKILL.md` for skill definitions.
- `lite.spec.steps/litespec-shared/*.md` for shared rules.

If you rename the source directory, update both the `go:embed` directive in `main.go` and `sourceTree` in `install.go`. If you move a bundled file outside those patterns, update the directive. Rebuild after editing a skill or rule so the executable includes the new content.

### Package for distribution

From the repository root, run the packaging command with `go` on your `PATH`.

```powershell
pwsh -File scripts/package.ps1 -Version v0.1.0
```

The script builds six binaries with `CGO_ENABLED=0` and embeds the supplied version, which you can check with `litespec --version`. It writes to `dist/` by default. Use `-OutputDirectory` to choose another folder.

| Platform | Architectures | Archive |
|---|---|---|
| Windows | x64, ARM64 | `.zip` |
| macOS | x64, ARM64 | `.tar.gz` |
| Linux | x64, ARM64 | `.tar.gz` |

Each archive contains the executable, `LICENSE`, and `THIRD_PARTY_LICENSES.txt`. `SHA256SUMS.txt` lists the checksums for the six archives.

### Publish a release

Use a version tag in the form `vX.Y.Z`, with an optional prerelease suffix such as `-rc.1`. Create it on the commit you want to release and push it to GitHub.

```bash
git tag v0.1.0
git push origin v0.1.0
```

GitHub Actions runs `go test` and `go vet` on Windows, macOS, and Linux. Once all checks pass, it uses the same packaging script and uploads the archives and checksums to GitHub Releases. Tags with a suffix such as `-rc.1` are published as prereleases.

## Workflow

The installer offers **Classic** for all agents and **Experimental Adaptive** for Codex, Claude Code, GitHub Copilot, Cursor, OpenCode, Gemini CLI and Qwen Code. Adaptive is still in early testing across all supported clients. In both modes a step delivers a verifiable outcome. In Adaptive the parent can assign an Easy implementation step to Sonnet or Sol, then resume control for verification. [Installer options](#choosing-execution-mode)

1. **Explore:** inspect relevant context and confirm the goal and scope.
2. **Propose:** prepare `spec.md` as an index and steps with context, tasks, and checks. A small change can use a single file.
3. **Apply:** execute authorized steps, review, run required checks, and report remaining work or readiness for Archive.
4. **Archive:** reconcile the same spec and affected living docs with final decisions, verify consistency, and archive. Invoke separately after Apply.

All generated content lives in `.litespec/`: active changes in `specs/<spec-name>/` (spec.md and steps), topic notes in `docs/` with an Obsidian-compatible `index.md`, and history in `archived/`.

**Modify (during an active change):** use `litespec-modify` when decisions or relevant files change. Apply also handles these revisions as they arise: update only affected specs and steps, reopen invalidated checks, and ask only about unresolved decisions. Valid agreements and unaffected progress are preserved; archived changes require a new linked change.

Documentation stays in the project at `.litespec/docs/`; Obsidian compatibility does not select an external vault. Each completed step records a short `Docs:` line (target topic and durable facts, or `none`) while the work is fresh; Archive consolidates those lines into small topic notes once, without rereading the whole change. A living-doc update becomes a step task only when the user requests it or other work needs it before closure. Closure verifies required docs and affected links, then reports documentation and archive paths. If no documentation update is needed, record why; do not create empty notes. Missing required documentation prevents closure.

Each `spec.md` records continuity (`preserve`, `extend`, `replace`, or `new`) and compatibility (`required`, `breaking-approved`, or `not-applicable`), with a concrete boundary for what to retain, replace, or migrate. This applies to code, documents, and other artifacts; tags alone do not authorize deletion. Record the policy once, without repeating it in every step.

Before archiving, verify tasks, acceptance, integration, compatibility, and documentation. Explicit archive authorization is also required and may be granted in advance; implementation permission alone is insufficient. Report anything missing and record `pending-verification` or `pending-confirmation` in spec.md with the outstanding item and next action so another session can resume.

**Verify (optional):** use `litespec-verify` for selected tasks, a step, or the whole active change. It records evidence and pending checks without implementing fixes or archiving; Apply still verifies its own work. Use `litespec-archive` for documentation and closure; unfinished implementation blocks archiving and is reported, not executed. Explicit documentation deliverables remain part of Apply; living-doc consolidation belongs to Archive.

## Install

Download the package for your operating system and architecture from [GitHub Releases](https://github.com/quiro90/liteSpec/releases), extract it once, and keep the executable wherever convenient. In the download filenames, `darwin` means macOS, `amd64` means x64, and `arm64` includes Apple Silicon. The binary includes all skills and works offline. It runs without Go, Node, or Python installed.

Open a terminal at the root of your project and run LiteSpec. For example, on Windows:

```powershell
& "C:\tools\litespec.exe" init
```

On Linux or macOS:

```bash
~/bin/litespec init
```

Use the path where you saved the executable. If you add it to your `PATH`, run `litespec init`. To install from another directory, add `--project "path to the project"`. Use `litespec --version` to check the version.

In an interactive terminal, choose Spanish or English first. Use ↑ and ↓ to move, Enter to select, and Esc to cancel. Pass `--lang en` or `--lang es` to skip the language choice. Redirected input uses numbered options and defaults to Spanish. Use `--plain` to select that mode manually.

Before the agent menu, `init` shows the version of the running executable and any project folders that already contain LiteSpec skills. Selecting an agent that uses one of those folders updates the bundled files and adjusts that agent's LiteSpec profiles to match your choices. Extra files and data in `.litespec/` are preserved.

Choose the agent. Codex and Claude Code then offer optional model configuration. Installation is local to the project:

| Agent | Destination | Adaptive |
|---|---|:---:|
| [Codex](https://learn.chatgpt.com/docs/build-skills) | `.agents/skills/` | ✅ exp. |
| [Claude Code](https://code.claude.com/docs/en/skills) | `.claude/skills/` | ✅ exp. |
| [GitHub Copilot](https://code.visualstudio.com/docs/agent-customization/agent-skills) | `.github/skills/` | ✅ exp. |
| [Cursor](https://cursor.com/docs/skills) | `.cursor/skills/` | ✅ exp. |
| [OpenCode](https://opencode.ai/docs/skills/) | `.opencode/skills/` | ✅ exp. |
| [Qoder CLI](https://docs.qoder.com/cli/Skills) | `.qoder/skills/` | — |
| [Gemini CLI](https://geminicli.com/docs/cli/skills/) | `.gemini/skills/` | ✅ exp. |
| [Qwen Code](https://qwenlm.github.io/qwen-code-docs/en/users/features/skills/) | `.qwen/skills/` | ✅ exp. |
| [Cline](https://docs.cline.bot/customization/skills) | `.cline/skills/` | — |
| [Devin Local](https://docs.devin.ai/desktop/devin-local/customizations) | `.devin/skills/` | — |
| [ADE](https://github.com/arul28/ADE/blob/main/apps/desktop/src/shared/agentSkillRoots.ts) | `.ade/skills/` | — |
| [Zed Agent](https://zed.dev/docs/ai/skills) | `.agents/skills/` | — |
| MiniMax Code | `.minimax/skills/` | — |

Zed Agent requires a trusted project and shares this destination with Codex. Auto model applies only in the client named by its marker; Zed keeps the normal workflow and preserves Codex configuration. For external agents inside Zed, select their own installer option. ADE uses project skills here, not its bundled resources/agent-skills directory.

The six skills and shared rules are copied. LICENSE stays at the repository root. Rules load as needed: `protocol.md` for all skills, `specification.md` when defining specifications, `revision.md` when revising changes, `verification.md` when checking results, `documentation.md` when consolidating living docs, and `closure.md` when archiving. In Adaptive, `adaptive-plan.md` when classifying steps, `adaptive-apply.md` when executing them and `easy-worker.md` for the Easy worker; `serial.md` only when `.litespec/serial/` exists. Do not load the entire folder by default. Reinstallation replaces only the listed package files in the seven LiteSpec folders; extra files and other skills are preserved. Destination links or file/directory conflicts stop installation before replacement.

The installer creates an empty `.litespec/` if missing and preserves its contents if present. The agent creates `specs/`, `docs/`, and `archived/` as needed during work; documentation impact is always assessed before closure.

If `.gitignore` already exists, the installer offers to exclude the LiteSpec skill folders. If the executable is in the project root, you can exclude it as well or choose **i/ins** to exclude only the executable. Enter keeps the file as it is. Existing rules and tracked files keep their status. You can reuse the same binary in other projects.

Start a new agent session and ask: **“Use litespec-explore for [your change].”** Then continue with `litespec-propose` and `litespec-apply`; you can request a specific step or all pending steps. Finish with `litespec-archive`. A clear explicit request can settle Explore without another confirmation; unresolved material questions still require answers. Confirming scope alone does not authorize implementation.

## Choosing execution mode

Codex and Claude Code offer two independent choices after agent selection.

| Setting | Options |
|---|---|
| Step execution | **1 Classic** (Enter) or **2 Experimental Adaptive**. In Adaptive, Easy uses the configurable `litespec-easy` profile. Enter when creating it selects `gpt-6.2-sol` in Codex or `sonnet` in Claude. |
| Internal skill delegation | **1 Disabled** or **2 Auto model by role**: read-only `search` and `plan` roles for analysis in any phase. Enter keeps the current role activation, initially disabled in a new project. |

Qoder CLI, Cline, Devin Local, ADE, Zed and MiniMax Code use Classic. Each installer run regenerates the configuration files for the chosen options and deletes those no longer selected; it touches only those exact files, so manual edits to them are replaced and other agents are preserved. Model and effort are asked on each run. Start a new client session to load them.

**Experimental Adaptive (GitHub Copilot, Cursor, OpenCode, Gemini CLI, Qwen Code).** After agent selection the installer asks only for step execution; Auto model roles remain exclusive to Codex and Claude Code. Adaptive creates the client's Easy worker (`.github/agents/litespec-easy.agent.md`, or `litespec-easy.md` in `.cursor/agents/`, `.opencode/agents/`, `.gemini/agents/` or `.qwen/agents/`) and `litespec-shared/adaptive-active.md`, a marker that names the client and how to invoke the worker; other clients ignore it. The model is optional: empty keeps the client default, so set a cheaper model to save quota (OpenCode uses `provider/model`; Copilot in VS Code uses names such as `Claude Sonnet 4.5 (copilot)` and Copilot CLI IDs such as `claude-sonnet-4.5`). Classic deletes both files. Not yet validated in real clients or surfaces (Copilot in VS Code or CLI): delegation may need to be enabled in the client, and any client may ignore or override the requested model.

Explore records contracts, patterns and acceptance examples. Propose groups code, tests and documentation by delivered outcome. In Adaptive it assigns residual difficulty, ownership and focused review where needed. Direct Apply fills missing phases and dispatches one eligible Easy step at a time. Standalone Verify checks scope, current evidence and risk boundaries.

To compare modes, start at the same revision with the same requirements, checks and role settings. Measure from Explore through final acceptance. Compare parent quota per accepted change, elapsed time, corrections and regressions. Each Adaptive step records `Executed:` (executor, principal or executor-then-principal) and its correction count. Record per-model usage as unknown when the client does not expose it.

**Optional single active spec.** Create the directory `.litespec/serial/` before starting sessions in this checkout. The first parent claims it for the invocation; a competing session reports contention and yields. Once the session returns, another can resume the active spec; new specs wait until archival. After an interruption check the owner note and confirm all writers have stopped before manually clearing `.litespec/serial/busy/`. Remove the empty serial directory when idle to opt out.

### Reconfigure profiles

Edit each role profile in `.codex/agents/` or `.claude/agents/`. Set `model` and a compatible `model_reasoning_effort` (Codex) or `effort` (Claude). Omitted fields use client defaults. Claude also accepts `model: inherit`. The Adaptive `litespec-easy` profile uses the same fields; to disable Adaptive manually, delete it. Rerunning the installer regenerates these profiles and replaces manual edits.

To switch modes, rerun the installer for the same client. To disable roles manually, delete the installed `litespec-shared/delegation-active.md` marker and the two profiles it lists. Then open a new session.

## License

[MIT](LICENSE) · Copyright (c) 2026 Juan Quiroga. Allows use, modification, and distribution, including commercial use, while retaining the copyright and license notices.

## Support the project

Consider donating if you find it useful:

<a href="https://cafecito.app/juanquiroga"><img src="https://cdn.cafecito.app/imgs/buttons/button_2.png" alt="Invitame un café en cafecito.app"></a> <a href="https://www.paypal.com/ncp/payment/PJXDUSBHSE8DE"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif" alt="Donate with PayPal"></a>
