---
name: speclite-apply
description: Execute selected or all SpecLite steps, verify outcomes, and archive completed changes.
---

Read the [shared rules](../speclite-shared/protocol.md).

1. Read spec.md. Require valid Explore confirmation, ready (or implementing) state, and authorization covering the work. Complete missing stages first; ask for authorization only if missing or insufficient.
2. Honor the requested steps; otherwise continue authorized pending work in dependency order. A step starts only after prerequisites are done; execute prerequisites if authorized, otherwise report the blocker. Load only the current step and necessary sources; check actual progress and freshness.
3. Mark implementing and the step active; execute its tasks. Resolve technical details within scope. Return material scope/behavior changes to Explore; continue independent authorized work.
4. Update checkboxes and record actual verification in the step; mark it done only when its acceptance, required checks and documentation pass. If unfinished, record remaining work/blocker and next action; update index status.
5. After all steps finish, verify overall acceptance and integration between steps; update `.liteSpec/docs/` and archive under shared closure rules. Partial execution never closes the change.
