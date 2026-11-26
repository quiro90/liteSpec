# LiteSpec

English | [Español](README.ES.md)

Short, clear specifications for working with AI agents while keeping token usage low. LiteSpec breaks work into small steps with enough context to execute and verify each one, without loading the entire project on every read.

Generated documentation follows the same goal: minimal, organized by topic, and useful for continuing work without reconstructing conversations.

## Workflow

The installer offers **Classic** for all agents and **Adaptive** for Claude Code and Codex. In both modes a step delivers a verifiable outcome. In Adaptive the parent can assign an Easy implementation step to Sonnet or Sol, then resume control for verification. [Installer options](#choosing-execution-mode)

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

Copy the complete `liste.spec.steps/` folder and the appropriate installer into the **root of the project where you will use LiteSpec**, side by side. No Python, Node, or additional downloads are required.

**Windows — PowerShell:**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\lite.spec.install.ps1
```

**Linux / macOS — Bash:**

```bash
bash ./lite.spec.install.sh
```

Choose the agent. Codex and Claude Code then offer optional model configuration. Installation is local to the project:

| Agent | Destination | Adaptive |
|---|---|:---:|
| [Codex](https://learn.chatgpt.com/docs/build-skills) | `.agents/skills/` | ✅ |
| [Claude Code](https://code.claude.com/docs/en/skills) | `.claude/skills/` | ✅ |
| [GitHub Copilot](https://code.visualstudio.com/docs/agent-customization/agent-skills) | `.github/skills/` | — |
| [Cursor](https://cursor.com/docs/skills) | `.cursor/skills/` | — |
| [OpenCode](https://opencode.ai/docs/skills/) | `.opencode/skills/` | — |
| [Qoder CLI](https://docs.qoder.com/cli/Skills) | `.qoder/skills/` | — |
| [Gemini CLI](https://geminicli.com/docs/cli/skills/) | `.gemini/skills/` | — |
| [Qwen Code](https://qwenlm.github.io/qwen-code-docs/en/users/features/skills/) | `.qwen/skills/` | — |
| [Cline](https://docs.cline.bot/customization/skills) | `.cline/skills/` | — |
| [Devin Local](https://docs.devin.ai/desktop/devin-local/customizations) | `.devin/skills/` | — |
| [ADE](https://github.com/arul28/ADE/blob/main/apps/desktop/src/shared/agentSkillRoots.ts) | `.ade/skills/` | — |
| [Zed Agent](https://zed.dev/docs/ai/skills) | `.agents/skills/` | — |
| MiniMax Code | `.minimax/skills/` | — |

Zed Agent requires a trusted project and shares this destination with Codex. Auto model applies only in the client named by its marker; Zed keeps the normal workflow and preserves Codex configuration. For external agents inside Zed, select their own installer option. ADE uses project skills here, not its bundled resources/agent-skills directory.

The six skills and shared rules are copied. LICENSE stays at the repository root. Rules load as needed: `protocol.md` for all skills, `specification.md` when defining specifications, `revision.md` when revising changes, `verification.md` when checking results, `documentation.md` when consolidating living docs, and `closure.md` when archiving. In Adaptive, `adaptive-plan.md` when classifying steps, `adaptive-apply.md` when executing them and `easy-worker.md` for the Easy worker; `serial.md` only when `.litespec/serial/` exists. Do not load the entire folder by default. Reinstallation replaces only the listed package files in the seven LiteSpec folders; extra files and other skills are preserved. Destination links or file/directory conflicts stop installation before replacement.

The installer creates an empty `.litespec/` if missing and preserves its contents if present. The agent creates `specs/`, `docs/`, and `archived/` as needed during work; documentation impact is always assessed before closure.

When upgrading an older installation, replace the `speclite-*` folders with `litespec-*` to avoid duplicate skills. Preserve `.liteSpec/` data when adopting `.litespec/`; these are distinct paths on case-sensitive systems. The installer does not migrate older installations.

At the end, `si`, `sí`, `yes`, or `y` confirms deletion of the installed source files and the installer you ran; any other response keeps them. Only empty folders are removed: additional files, documentation, and project code are preserved.

If `.gitignore` already exists, the final prompt offers **y/yes/si/s** for the installer (executed script and source folder) plus the seven LiteSpec skill folders, **i/ins** for the installer only, or any other answer to leave it unchanged. Existing rules are preserved; only missing exclusions are appended. Git, when available, also recognizes ignore patterns; without Git, literal rules and parent directories are checked. No new .gitignore is created, and already tracked files remain tracked.

Start a new agent session and ask: **“Use litespec-explore for [your change].”** Then continue with `litespec-propose` and `litespec-apply`; you can request a specific step or all pending steps. Finish with `litespec-archive`. A clear explicit request can settle Explore without another confirmation; unresolved material questions still require answers. Confirming scope alone does not authorize implementation.

## Choosing execution mode

Codex and Claude Code offer two independent choices after agent selection.

| Setting | Options |
|---|---|
| Step execution | **1 Classic** (Enter) or **2 Adaptive**. In Adaptive, Easy uses the configurable `litespec-easy` profile. Enter when creating it selects `gpt-6.2-sol` in Codex or `sonnet` in Claude. |
| Internal skill delegation | **1 Disabled** or **2 Auto model by role**: read-only `search` and `plan` roles for analysis in any phase. Enter keeps the current role activation, initially disabled in a new project. |

Other agents use Classic. The installer saves and restores customized profiles. The former `implement` role is retired: any Codex or Claude Code run moves it to `.litespec/disabled-agents/` and regenerates an older activation marker; implementation delegation now belongs to Adaptive only. Model and effort are configurable at creation. Start a new client session to load them.

Explore records contracts, patterns and acceptance examples. Propose groups code, tests and documentation by delivered outcome. In Adaptive it assigns residual difficulty, ownership and focused review where needed. Direct Apply fills missing phases and dispatches one eligible Easy step at a time. Standalone Verify checks scope, current evidence and risk boundaries.

To compare modes, start at the same revision with the same requirements, checks and role settings. Measure from Explore through final acceptance. Compare parent quota per accepted change, elapsed time, corrections and regressions. Each Adaptive step records `Executed:` (executor, principal or executor-then-principal) and its correction count. Record per-model usage as unknown when the client does not expose it.

**Optional single active spec.** Create the directory `.litespec/serial/` before starting sessions in this checkout. The first parent claims it for the invocation; a competing session reports contention and yields. Once the session returns, another can resume the active spec; new specs wait until archival. After an interruption check the owner note and confirm all writers have stopped before manually clearing `.litespec/serial/busy/`. Remove the empty serial directory when idle to opt out.

### Reconfigure profiles

Edit each role profile in `.codex/agents/` or `.claude/agents/`. Set `model` and a compatible `model_reasoning_effort` (Codex) or `effort` (Claude). Omitted fields use client defaults. Claude also accepts `model: inherit`. The Adaptive `litespec-easy` profile uses the same fields; to disable Adaptive manually, move it to `.litespec/disabled-agents/codex/` or `.litespec/disabled-agents/claude/`.

To switch modes, rerun the installer for the same client, copying a fresh package if needed. To disable roles manually, move the installed `litespec-shared/delegation-active.md` marker and the two profiles it lists to `.litespec/disabled-agents/codex/` or `.litespec/disabled-agents/claude/`. Restore each file to its original location to reactivate. Resolve any duplicate active and saved copies before switching, then open a new session.

## License

[MIT](LICENSE) · Copyright (c) 2026 Juan Quiroga. Allows use, modification, and distribution, including commercial use, while retaining the copyright and license notices.

## Support the project

Consider donating if you find it useful:

<a href="https://cafecito.app/juanquiroga"><img src="https://cdn.cafecito.app/imgs/buttons/button_2.png" alt="Invitame un café en cafecito.app"></a> <a href="https://www.paypal.com/ncp/payment/PJXDUSBHSE8DE"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif" alt="Donate with PayPal"></a>
