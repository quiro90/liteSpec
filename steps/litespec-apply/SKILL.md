---
name: litespec-apply
description: Execute selected or all LiteSpec steps, verify outcomes, and archive completed changes.
---

Read the [shared rules](../litespec-shared/protocol.md).

1. Read spec.md, including continuity/compatibility constraints. If the policy is missing or unclear, read the [specification contract](../litespec-shared/specification.md) and resolve material gaps. Require valid Explore confirmation, ready (or implementing) state, and authorization covering the work. Complete missing stages first; ask for authorization only if missing or insufficient.
2. Honor the requested steps; otherwise continue authorized pending work in dependency order. A step starts only after prerequisites are done; execute prerequisites if authorized, otherwise report the blocker. Load only the current step and necessary sources; check actual progress and freshness.
3. Mark implementing and the step active; execute its tasks. Resolve technical details within scope. For changed user decisions or relevant source discrepancies, read and follow [incremental revision](../litespec-shared/revision.md) before continuing affected work; preserve independent authorized progress.
4. When maintaining living docs, read [documentation and closure](../litespec-shared/closure.md). Update checkboxes and record actual verification in the step; mark it done only when its acceptance, required checks and documentation pass. If unfinished, record remaining work/blocker and next action; update index status.
5. After all steps finish, read and execute [closure gates](../litespec-shared/closure.md). Partial execution never closes the change.
