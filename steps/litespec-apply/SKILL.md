---
name: litespec-apply
description: Execute authorized LiteSpec steps, verify outcomes, or resume only documentation and closure.
---

Read the [shared rules](../litespec-shared/protocol.md).

1. Read spec.md, including continuity/compatibility constraints. For a closure-only request, go directly to [closure](../litespec-shared/closure.md): update required docs within authorization, verify, and report unfinished implementation without executing it. Otherwise require valid Explore confirmation, ready (or implementing) state, and authorization covering the work. Complete missing stages; resolve missing policy through the [specification contract](../litespec-shared/specification.md).
2. Honor requested steps; otherwise continue authorized pending work in dependency order. Start only after prerequisites are done; execute them if authorized, otherwise report the blocker. Load only the current step and necessary sources; check progress and freshness.
3. Mark implementing and the step active; execute its tasks. Resolve technical details within scope. For changed decisions or source discrepancies, follow [incremental revision](../litespec-shared/revision.md); preserve independent authorized progress.
4. Update required docs using [documentation rules](../litespec-shared/closure.md), then follow [verification](../litespec-shared/verification.md) for the step.
5. After all steps finish, execute [closure](../litespec-shared/closure.md). Partial execution never closes the change.
