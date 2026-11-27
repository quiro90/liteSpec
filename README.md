# LiteSpec

English | [Español](README.ES.md)

Short, clear specifications for working with AI agents while keeping token usage low. LiteSpec breaks work into small steps with enough context to execute and verify each one, without loading the entire project on every read.

Generated documentation follows the same goal: minimal, organized by topic, and useful for continuing work without reconstructing conversations.

> **Experimental.** LiteSpec as a whole is experimental: the workflow, Adaptive, delegation and installer may change between versions and have not been validated in every client. Review the specs, changes and checks an agent produces before relying on them.

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

A direct `go build` uses the version declared in `main.go`. The packaging script embeds the version supplied through `-Version`. GitHub Actions supplies the release tag.

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

The installer offers **Classic** for all agents and **Experimental Adaptive** for Codex, Claude Code, GitHub Copilot, Cursor, OpenCode, Gemini CLI, Antigravity and Qwen Code. Adaptive is still in early testing across all supported clients. In both modes a step delivers a verifiable outcome. In Adaptive the parent splits independently checkable work, delegates Easy and Medium steps and verifies the results. [Installer options](#choosing-execution-mode)

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
& "C:\tools\litespec.exe"
```

On Linux or macOS:

```bash
~/bin/litespec
```

Use the path where you saved the executable. If you add it to your `PATH`, run `litespec`. Use the `init` subcommand when passing installer options. For example, `litespec init --project "path to the project"` installs into another directory. Use `litespec --version` to check the version.

In an interactive terminal, choose Spanish or English first. In the agent menu, use ↑ and ↓ to move, **Space** to mark or unmark an agent, **Enter** to confirm, and **Esc** to cancel. Run `litespec init --lang en` or `litespec init --lang es` to skip the language choice. With redirected input or `litespec init --plain`, enter one number or a comma-separated list such as `1,2,4`.

Before the agent menu, the installer shows the version of the running executable and any project folders that already contain LiteSpec skills. Selecting an agent that uses one of those folders updates the bundled files and adjusts that agent's LiteSpec profiles to match your choices. Extra files and data in `.litespec/` are preserved.

You can install LiteSpec for multiple agents in one run. The installer asks for the mode and configuration of each agent that offers those options. Installation is local to the project:

| Agent | Destination | Adaptive | Delegation |
|---|---|:---:|:---:|
| [Codex](https://learn.chatgpt.com/docs/build-skills) | `.agents/skills/` | ✅ exp. | ✅ exp. |
| [Claude Code](https://code.claude.com/docs/en/skills) | `.claude/skills/` | ✅ exp. | ✅ exp. |
| [GitHub Copilot](https://code.visualstudio.com/docs/agent-customization/agent-skills) | `.github/skills/` | ✅ exp. | ✅ exp. |
| [Cursor](https://cursor.com/docs/skills) | `.cursor/skills/` | ✅ exp. | ✅ exp. |
| [OpenCode](https://opencode.ai/docs/skills/) | `.opencode/skills/` | ✅ exp. | ✅ exp. |
| [Qoder CLI](https://docs.qoder.com/cli/Skills) | `.qoder/skills/` | — | — |
| [Gemini CLI](https://geminicli.com/docs/cli/skills/) | `.gemini/skills/` | ✅ exp. | ✅ exp. |
| [Antigravity (App / CLI)](https://antigravity.google/docs/skills) | `.agents/skills/` | ✅ exp. | ✅ exp. |
| [Qwen Code](https://qwenlm.github.io/qwen-code-docs/en/users/features/skills/) | `.qwen/skills/` | ✅ exp. | ✅ exp. |
| [Cline](https://docs.cline.bot/customization/skills) | `.cline/skills/` | — | — |
| [Devin Local](https://docs.devin.ai/desktop/devin-local/customizations) | `.devin/skills/` | — | — |
| [ADE](https://github.com/arul28/ADE/blob/main/apps/desktop/src/shared/agentSkillRoots.ts) | `.ade/skills/` | — | — |
| [Zed Agent](https://zed.dev/docs/ai/skills) | `.agents/skills/` | — | — |
| MiniMax Code | `.minimax/skills/` | — | — |

Codex, Antigravity and Zed share `.agents/skills/` and its Delegation setting. Zed requires a trusted project. For external agents inside Zed, select their own installer option. ADE uses project skills here, not its bundled resources/agent-skills directory.

The six skills and shared rules are copied. LICENSE stays at the repository root. Rules load as needed: `protocol.md` for all skills, `specification.md` when defining specifications, `revision.md` when revising changes, `verification.md` when checking results, `documentation.md` when consolidating living docs, and `closure.md` when archiving. In Adaptive, `adaptive-plan.md` when classifying steps, `adaptive-apply.md` when executing them and `executor.md` for the Easy and Medium workers; `serial.md` only when `.litespec/serial/` exists. Do not load the entire folder by default. Reinstallation replaces only the listed package files in the seven LiteSpec folders; extra files and other skills are preserved. Destination links or file/directory conflicts stop installation before replacement.

The installer creates an empty `.litespec/` if missing and preserves its contents if present. The agent creates `specs/`, `docs/`, and `archived/` as needed during work; documentation impact is always assessed before closure.

If `.gitignore` already exists, the installer asks once at the end whether to exclude the LiteSpec skills you just installed. If the executable is in the project root, you can exclude the skills, the executable, or both. Enter keeps the file as it is. Existing rules and tracked files keep their status. You can reuse the same binary in other projects.

Start a new agent session and ask: **“Use litespec-explore for [your change].”** Then continue with `litespec-propose` and `litespec-apply`; you can request a specific step or all pending steps. Finish with `litespec-archive`. A clear explicit request can settle Explore without another confirmation; unresolved material questions still require answers. Confirming scope alone does not authorize implementation.

## Choosing execution mode

Clients marked for Delegation above offer two independent options. For GitHub Copilot, delegation applies to VS Code and Copilot CLI.

| Setting | Options |
|---|---|
| Step execution | **1 Classic** (Enter) or **2 Experimental Adaptive**. In Adaptive, Easy steps (mechanical: commands, named values, an existing pattern) and Medium steps (real logic, fully specified, with a check that demonstrates the result) go to their workers. The parent keeps Hard steps: open decisions, a measurement before design or an undefined integration contract. |
| Delegation | **1 Disabled** or **2 Allow subagent lookups** during Explore, Propose and Modify. The parent decides scope and design. Enter keeps the setting for the skills destination. It defaults to disabled. |

Both options can be combined. Delegation applies when the parent runs Explore, Propose or Modify; revisions that Apply resolves on its own do not use it, so invoke `litespec-modify` for a larger revision. Adaptive only decides who executes steps during Apply.

Qoder CLI, Cline, Devin Local, ADE, Zed and MiniMax Code use Classic. Each installer run regenerates the configuration files for the chosen options and deletes those no longer selected; it touches only those exact files, so manual edits to them are replaced and other agents are preserved. Adaptive prompts for worker models and, where supported, effort. Start a new client session to load them.

**Experimental Adaptive (GitHub Copilot, Cursor, OpenCode, Gemini CLI, Antigravity, Qwen Code).** These clients offer a single executor (`litespec-executor`) for Easy and Medium steps and use the client named in `litespec-shared/adaptive-active.md` to invoke it. Classic removes the worker and marker. Enter selects `gemini-4-hydrogen` in Gemini CLI, `composer-2.5[]` in Cursor and `anthropic/claude-haiku-4-5` in OpenCode with an Anthropic provider available. Enter uses the client model in GitHub Copilot and Qwen Code. In Cursor, OpenCode and Gemini CLI, enter `inherit` to use the session model. Copilot uses display names in VS Code and model IDs in Copilot CLI. Model availability and delegation depend on the client.

Antigravity shares `.agents/skills/` with Codex and Zed. Adaptive installs the executor at `.agents/agents/litespec-executor.md`. Enter selects the fast `flash` tier. To use Hydrogen explicitly, select it in the session and choose `inherit` for the executor. The `pro` tier is also supported. [Google Antigravity](https://antigravity.google/docs/subagents?app=cli)

Explore records contracts, patterns and acceptance examples. Propose groups code, tests and documentation by delivered outcome. In Adaptive each step records one level, e.g. `Execution: medium`, with focused review where needed. Extract separately testable work and link its dependents. After a Hard decision, rate the remaining implementation again. Direct Apply fills missing phases and dispatches one eligible step at a time. Standalone Verify checks scope, current evidence and risk boundaries.

To compare modes, start at the same revision with the same requirements, checks and role settings. Measure from Explore through final acceptance. Compare parent quota per accepted change, elapsed time, corrections and regressions. Each Adaptive step records `Executed:` (executor, principal or executor-then-principal) and its correction count. Record per-model usage as unknown when the client does not expose it.

**Optional single active spec.** Create the directory `.litespec/serial/` before starting sessions in this checkout. The first parent claims it for the invocation; a competing session reports contention and yields. Once the session returns, another can resume the active spec; new specs wait until archival. After an interruption check the owner note and confirm all writers have stopped before manually clearing `.litespec/serial/busy/`. Remove the empty serial directory when idle to opt out.

### Reconfigure profiles

During installation, Enter accepts the model shown next to each profile.

| Mode and profile | Codex | Claude Code |
|---|---|---|
| Adaptive · Easy (`easy`) | `gpt-6-luna` | `haiku` |
| Adaptive · Medium (`medium`) | `gpt-6.2-sol` | `sonnet` |

For the parent session, the installer suggests Astra or Opus, since the parent explores, drafts the specs, handles Hard steps and verifies the workers. Select the parent model in the client. Each profile defaults to `medium` effort. Enter another supported level such as `high`, or use `inherit` in either field to let the client choose the model or effort. Claude Code model alias versions depend on the provider.

Edit each role profile in `.codex/agents/` or `.claude/agents/`. Set `model` and a compatible `model_reasoning_effort` (Codex) or `effort` (Claude). Omitted fields use client defaults. Claude also accepts `model: inherit`. To disable Adaptive manually in Codex or Claude Code, delete the `litespec-easy` and `litespec-medium` profiles. Reinstalling removes the retired `litespec-very-easy` profile, the single worker's old `litespec-easy` name and `easy-worker.md`. Rerunning the installer regenerates these profiles and replaces manual edits.

Enabling Delegation installs `litespec-shared/delegation.md` and keeps its direct link in Explore, Propose and Modify. When disabled, the installer removes both the file and the link from the installed skills. For a shared folder the installer asks once, names the clients the choice applies to, and reinstalling Zed alone preserves it. An upgrade uses the former AutoMode setting as the initial choice and removes its marker. Reinstalling Codex or Claude Code removes the retired `litespec-search`, `litespec-plan` and `litespec-research` profiles for that client; reinstalling only Antigravity or Zed leaves Codex's, which nothing uses and you can delete. The installer removes the link only when it matches the bundled text, so a hand-edited link line in an installed skill may remain after disabling Delegation. Start a new session to apply the choice.

## Version numbering

LiteSpec uses the `vMAJOR.MINOR.PATCH` format.

- **Patch** increases for interface changes and small fixes.
- **Minor** increases for medium-sized changes to the specification or when the patch number has reached `999`.
- **Major** increases for a substantial change to LiteSpec or when the minor number has reached `999`.

Increasing the minor version resets the patch number to `0` (`v0.1.999` → `v0.2.0`). Increasing the major version resets both to `0` (`v0.999.0` → `v1.0.0`).

## License

[MIT](LICENSE) · Copyright (c) 2026 Juan Quiroga. Allows use, modification, and distribution, including commercial use, while retaining the copyright and license notices.

## Support the project

Consider donating if you find it useful:

<a href="https://cafecito.app/juanquiroga"><img src="https://cdn.cafecito.app/imgs/buttons/button_2.png" alt="Invitame un café en cafecito.app"></a> <a href="https://www.paypal.com/ncp/payment/PJXDUSBHSE8DE"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif" alt="Donate with PayPal"></a>
