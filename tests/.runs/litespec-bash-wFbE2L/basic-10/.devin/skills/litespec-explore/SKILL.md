---
name: litespec-explore
description: Inspect a LiteSpec change and confirm its intended outcome with the user before specification or implementation.
---

Read the [shared rules](../litespec-shared/protocol.md) and [specification contract](../litespec-shared/specification.md).

1. Read applicable AGENTS.md. Start with `.litespec/docs/index.md` and relevant topic notes if present, then other relevant documentation; verify findings against targeted source material. Search by goal keywords, paths, classes, and symbols; inspect matching sections, not whole folders/files. Expand only to resolve a concrete gap; stop when outcome, scope, and affected artifacts are understood. Consult `.litespec/archived/` only to reconstruct a specific missing decision or rationale. Separate verified facts, assumptions, and unresolved decisions.
2. Explain outcome and scope; recommend an option when alternatives matter. Resolve continuity/compatibility under the specification contract. Apply the shared agreement rule; wait for answers only to unresolved material questions.
3. Record the agreement and continuity policy in spec.md, plus only findings needed for specification or implementation. Mark Explore confirmed only when material questions are resolved; otherwise record what remains. Keep the change draft for Propose.

For revisions to an existing active change, read and follow [incremental revision](../litespec-shared/revision.md) instead of restarting exploration. Do not implement.
