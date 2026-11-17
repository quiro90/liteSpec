# Native delegation (experimental)

Optional automation using models assigned to specific responsibilities. It does not guarantee token or quota savings; the parent still consumes resources and coordination can increase usage. Native support, loaded configuration, account access and higher-priority instructions determine availability.

When `delegation-active.md` is present, use only its adapter and named agents. Delegate substantial bounded work when useful; use direct tools for trivial tasks. Search returns evidence, plan returns analysis/proposals, implement executes authorized work and verifies it. Roles are not LiteSpec stages. The parent owns agreements, spec status, integration and Archive; Apply still verifies its work.

Send only objective, necessary paths/evidence, authorized scope, constraints, checks and expected output. Prefer a fresh context over forwarding the conversation. Run at most one worker at a time; no recursive delegation or concurrent writers. Workers must read applicable AGENTS.md and the shared protocol, but must not delegate again. Search/plan must not edit. Instructions are not a separate read-only sandbox in Codex. In Claude, restrict search/plan to Read/Grep/Glob.

Never expand permissions, authorize implementation or archive through delegation. Preserve existing user changes. Return paths, changes or findings, checks/results, uncertainty and next action. The parent reviews relevant results without repeating the entire task. Resume from spec/step state and actual file changes; interrupted workers may have partial edits.

If delegation is unavailable, restricted, unloaded, or fails because of model/effort/quota: report once and continue with the current agent within existing authorization. Do not retry indefinitely, silently select another provider/API, or claim a configured model was actually used without runtime evidence. Distinguish requested model from observed model; native overrides/fallbacks may apply. If continuing is impossible, report the blocker.

## Reconfigure or disable after deleting the installer

Edit the role files' `model` and effort fields directly. Codex uses `model_reasoning_effort` and Claude uses `effort`. Omitted values follow each client's defaults. When changing models, choose a compatible effort if needed. Claude also supports `model: inherit`.

To change modes, copy a fresh package if needed and rerun the installer for the same agent. **Normal** moves LiteSpec's role files and activation marker out of the active directories. **Auto model** restores them, including custom models and effort settings. If an active file and its saved counterpart both exist, resolve the duplicate before retrying.

To switch modes manually, move `delegation-active.md` from this directory and the three role files listed in it to `.litespec/disabled-agents/codex/` or `.litespec/disabled-agents/claude/`. Restore each file to its original location to reactivate Auto model. Open a new agent session after switching modes.
