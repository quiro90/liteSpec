# Incremental revision

Use for changed user decisions or sources differing from findings; litespec-modify is the explicit entry point. Archives are immutable: start a linked change through Explore.

1. Read spec.md, the current/affected step, and relevant deltas using recorded paths/symbols and targeted searches. Expand only for missing details or changed dependency contracts.
2. Apply shared agreement rules. Resolve technical adjustments within agreed behavior and authorization. Preserve user edits; ask unresolved scope, behavior, acceptance, or edit-conflict questions. Pause affected work awaiting answers; continue independent authorized work.
3. When rewriting specs, read the [specification contract](specification.md). Replace stale decisions, context, tasks, acceptance, and prerequisite interfaces. Retain agreements/authorizations only where they cover revised scope, continuity, and closure. Add/remove steps as needed; keep dependencies acyclic. Follow invalidated dependents, including done steps; stop at unchanged contracts.
4. Reopen affected done steps as pending (blocked awaiting answers); invalidate only affected checkboxes/evidence. Preserve other progress. Keep implementing once execution begins; otherwise draft while material questions remain, ready when specified. Record blockers and next actions, not revision logs. Recheck affected acceptance/integration before closure. Update affected docs once behavior is verified, following [documentation rules](closure.md). Spec edits do not authorize implementation.
