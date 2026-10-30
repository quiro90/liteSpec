---
name: speclite-apply
description: Execute selected or all SpecLite steps, verify outcomes, and archive completed changes.
---

Read the [shared rules](../speclite-shared/protocol.md).

1. Read spec.md. Require valid Explore confirmation, ready (or implementing) state, and authorization covering the work. Complete missing stages first; ask for authorization only if missing or insufficient.
2. Honor the requested steps; otherwise continue authorized pending work in dependency order. A step starts only after prerequisites are done; execute prerequisites if authorized, otherwise report the blocker. Load only the current step and necessary sources; check actual progress and freshness.
3. Mark implementing and the step active; execute its tasks. Resolve technical details within scope. For changed user decisions or relevant source discrepancies, follow shared incremental revision rules before continuing affected work; preserve independent authorized progress.
4. Update checkboxes and record actual verification in the step; mark it done only when its acceptance, required checks and documentation pass. If unfinished, record remaining work/blocker and next action; update index status.
5. After all steps finish, verify overall acceptance and integration between steps; update and verify `.liteSpec/docs/`, record the documentation paths/results, and archive only after shared closure checks pass. Partial execution never closes the change.
