# LiteSpec

English | [Español](README.ES.md)

Short, clear specifications for working with AI agents while keeping token usage low. LiteSpec breaks work into small steps with enough context to execute and verify each one, without loading the entire project on every read.

Generated documentation follows the same goal: minimal, organized by topic, and useful for continuing work without reconstructing conversations.

## Workflow

1. **Explore:** inspect relevant context and confirm the goal and scope.
2. **Propose:** prepare `spec.md` as an index and steps with context, tasks, and checks. A small change can use a single file.
3. **Apply:** execute authorized steps, verify, update documentation, and archive.

All generated content lives in `.litespec/`: active changes in `specs/<spec-name>/` (spec.md and steps), topic notes in `docs/` with an Obsidian-compatible `index.md`, and history in `archived/`.

**Modify (during an active change):** use `litespec-modify` when decisions or relevant files change. Apply also handles these revisions as they arise: update only affected specs and steps, reopen invalidated checks, and ask only about unresolved decisions. Valid agreements and unaffected progress are preserved; archived changes require a new linked change.

Documentation stays in the project at `.litespec/docs/`; Obsidian compatibility does not select an external vault. Closure verifies required docs and affected links, then reports documentation and archive paths. If no documentation update is needed, record why; do not create empty notes. Missing required documentation prevents closure.

Each `spec.md` records continuity (`preserve`, `extend`, `replace`, or `new`) and compatibility (`required`, `breaking-approved`, or `not-applicable`), with a concrete boundary for what to retain, replace, or migrate. This applies to code, documents, and other artifacts; tags alone do not authorize deletion. Record the policy once, without repeating it in every step.

Before archiving, verify tasks, acceptance, integration, compatibility, and documentation. Explicit archive authorization is also required and may be granted in advance; implementation permission alone is insufficient. Report anything missing and record `pending-verification` or `pending-confirmation` in spec.md with the outstanding item and next action so another session can resume.

**Verify (optional):** use `litespec-verify` for selected tasks, a step, or the whole active change. It records evidence and pending checks without implementing fixes or archiving; Apply still verifies its own work. To resume only documentation and closure, ask `litespec-apply` to do so; unfinished implementation is reported, not executed.

## Install

Copy the complete `steps/` folder and the appropriate installer into the **root of the project where you will use LiteSpec**, side by side. No Python, Node, or additional downloads are required.

**Windows — PowerShell:**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

**Linux / macOS — Bash:**

```bash
bash ./install.sh
```

Choose the agent (not the model). Installation is local to the project:

| Agent | Destination |
|---|---|
| [Codex](https://learn.chatgpt.com/docs/build-skills) | `.agents/skills/` |
| [Claude Code](https://code.claude.com/docs/en/skills) | `.claude/skills/` |
| [GitHub Copilot](https://code.visualstudio.com/docs/agent-customization/agent-skills) | `.github/skills/` |
| [Cursor](https://cursor.com/docs/skills) | `.cursor/skills/` |
| [OpenCode](https://opencode.ai/docs/skills/) | `.opencode/skills/` |
| [Qoder CLI](https://docs.qoder.com/cli/Skills) | `.qoder/skills/` |
| [Gemini CLI](https://geminicli.com/docs/cli/skills/) | `.gemini/skills/` |
| [Qwen Code](https://qwenlm.github.io/qwen-code-docs/en/users/features/skills/) | `.qwen/skills/` |
| [Cline](https://docs.cline.bot/customization/skills) | `.cline/skills/` |
| [Devin Local](https://docs.devin.ai/desktop/devin-local/customizations) | `.devin/skills/` |
| [ADE](https://github.com/arul28/ADE/blob/main/apps/desktop/src/shared/agentSkillRoots.ts) | `.ade/skills/` |
| [Zed Agent](https://zed.dev/docs/ai/skills) | `.agents/skills/` |

Zed Agent requires a trusted project and shares this destination with Codex. For external agents inside Zed, select their own installer option. ADE uses project skills here, not its bundled resources/agent-skills directory.

The five skills and shared rules are copied. LICENSE stays at the repository root. Rules load as needed: `protocol.md` for all skills, `specification.md` when defining specifications, `revision.md` when revising changes, `verification.md` when checking results, and `closure.md` when maintaining documentation or closing. Do not load the entire folder by default. Reinstallation replaces only the ten listed package files in the six LiteSpec folders; extra files and other skills are preserved. Destination links or file/directory conflicts stop installation before replacement.

The installer creates an empty `.litespec/` if missing and preserves its contents if present. The agent creates `specs/`, `docs/`, and `archived/` as needed during work; documentation impact is always assessed before closure.

When upgrading an older installation, replace the `speclite-*` folders with `litespec-*` to avoid duplicate skills. Preserve `.liteSpec/` data when adopting `.litespec/`; these are distinct paths on case-sensitive systems. The installer does not migrate older installations.

At the end, `si`, `sí`, `yes`, or `y` confirms deletion of the installed source files and the installer you ran; any other response keeps them. Only empty folders are removed: additional files, documentation, and project code are preserved.

Start a new agent session and ask: **“Use litespec-explore for [your change].”** Then continue with `litespec-propose` and `litespec-apply`; you can request a specific step or all pending steps. A clear explicit request can settle Explore without another confirmation; unresolved material questions still require answers. Confirming scope alone does not authorize implementation.

## License

[MIT](LICENSE) · Copyright (c) 2026 Juan Quiroga. Allows use, modification, and distribution, including commercial use, while retaining the copyright and license notices.

## Support the project

Consider donating if you find it useful:

<a href="https://cafecito.app/juanquiroga"><img src="https://cdn.cafecito.app/imgs/buttons/button_2.png" alt="Invitame un café en cafecito.app"></a> <a href="https://www.paypal.com/ncp/payment/PJXDUSBHSE8DE"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif" alt="Donate with PayPal"></a>
