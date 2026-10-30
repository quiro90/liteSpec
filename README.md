# SpecLite

English | [Español](README.ES.md)

Short, clear specifications for working with AI agents while keeping token usage low. SpecLite breaks work into small steps with enough context to execute and verify each one, without loading the entire project on every read.

Generated documentation follows the same goal: minimal, organized by topic, and useful for continuing work without reconstructing conversations.

## Workflow

1. **Explore:** inspect relevant context and confirm the goal and scope.
2. **Propose:** prepare `spec.md` as an index and steps with context, tasks, and checks. A small change can use a single file.
3. **Apply:** execute authorized steps, verify, update documentation, and archive.

All generated content lives in `.liteSpec/`: active changes, topic notes in `docs/` with an Obsidian-compatible `index.md`, and history in `archived/`.

**Modify (during an active change):** use `speclite-modify` when decisions or relevant files change. Apply also handles these revisions as they arise: update only affected specs and steps, reopen invalidated checks, and ask only about unresolved decisions. Valid agreements and unaffected progress are preserved; archived changes require a new linked change.

Documentation stays in the project at `.liteSpec/docs/`; Obsidian compatibility does not select an external vault. Closure verifies the index, affected topic links, and current content, then reports documentation and archive paths. Missing required documentation prevents closure.

Each `spec.md` records continuity (`preserve`, `extend`, `replace`, or `new`) and compatibility (`required`, `breaking-approved`, or `not-applicable`), with a concrete boundary for what to retain, replace, or migrate. This applies to code, documents, and other artifacts; tags alone do not authorize deletion. Record the policy once, without repeating it in every step.

Before archiving, verify tasks, acceptance, integration, compatibility, and documentation. Explicit archive authorization is also required and may be granted in advance; implementation permission alone is insufficient. Report anything missing and record `pending-verification` or `pending-confirmation` in spec.md with the outstanding item and next action so another session can resume.

## Install

Copy the complete `steps/` folder and the appropriate installer into the **root of the project where you will use SpecLite**, side by side. No Python, Node, or additional downloads are required.

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

The four skills, shared rules, and license are copied. Rules load as needed: `protocol.md` for all skills, `specification.md` when defining specifications, `revision.md` when revising changes, and `closure.md` when maintaining documentation or closing. Do not load the entire folder by default. If any SpecLite folder already exists at the destination, installation stops without overwriting it: review it before reinstalling. Other skills are preserved.

At the end, `si`, `sí`, `yes`, or `y` confirms deletion of the installed source files and the installer you ran; any other response keeps them. Only empty folders are removed: additional files, documentation, and project code are preserved.

Start a new agent session and ask: **“Use speclite-explore for [your change].”** Then continue with `speclite-propose` and `speclite-apply`; you can request a specific step or all pending steps. Confirming scope does not automatically authorize implementation.

## License

[MIT](LICENSE) · Copyright (c) 2026 Juan Quiroga. Allows use, modification, and distribution, including commercial use, while retaining the copyright and license notices.

## Support the project

Consider donating if you find it useful:

<a href="https://cafecito.app/juanquiroga"><img src="https://cdn.cafecito.app/imgs/buttons/button_2.png" alt="Invitame un café en cafecito.app"></a> <a href="https://www.paypal.com/ncp/payment/PJXDUSBHSE8DE"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif" alt="Donate with PayPal"></a>
