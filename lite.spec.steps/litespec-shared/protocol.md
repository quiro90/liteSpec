# Shared rules

Follow project instructions identified by the user or client. Load required rules only when missing from context or changed.

Assigned workers: follow the parent assignment. For an Easy or Medium implementation step use the [executor instructions](executor.md). Stop reading this protocol here.

Parent sessions: if the project directory `.litespec/serial/` exists, acquire the [single-change claim](serial.md) before proceeding.

Adaptive execution is active only in Codex with project `.codex/agents/litespec-medium.toml`, or Claude Code with `.claude/agents/litespec-medium.md`. In other clients it is active only if sibling `adaptive-active.md` exists, names the current client and its native worker file exists; then read it. Otherwise ignore Adaptive rules.

- **Language:** use the user's language for communication and new specs; preserve existing document languages, paths, skill names, states, and policy tags.
- **Record:** keep each change's spec.md, steps, and notes in `.litespec/specs/<spec-name>/` relative to the project root. Create directories as needed without collisions. Preserve enough context to resume without conversation history.
- **Agreement:** record the explicit request/answers and agreed scope in spec.md. Clear requests settle Explore; ask only unresolved material questions. Suggestions and source edits are not agreements. Record implementation and archive authorizations separately with their scopes; scope confirmation and ready status authorize neither. Reuse valid agreements; never invent them.
- **States:** change = draft (material unknowns) / ready (specified) / implementing (including interrupted work) / done (closed). Step = pending / active / blocked / done, stored only in the index or beside an inline step.
- **Freshness:** reuse current findings. Recheck only the affected sections when inputs change, evidence conflicts or a check fails. Use incremental revision for discrepancies.

## Minimal context

Keep execution guidance, constraints, unresolved decisions, rationale preventing rediscovery, and evidence. Prefer concise fields, concrete paths/symbols, and references. Omit empty sections, duplication, transcripts, large excerpts, and work logs; never copy these rules into specs.

Use spec.md and the current step. Open only the source sections needed for the task. Consult other notes or steps only to fill a specific gap.
