---
name: litespec-explore
description: Inspect a LiteSpec change and confirm its intended outcome with the user before specification or implementation.
---

Read the [shared rules](../litespec-shared/protocol.md) and [specification contract](../litespec-shared/specification.md).

1. Start with `.litespec/docs/index.md` and relevant topic notes if present, then other relevant documentation; verify findings against targeted source material. Search by goal keywords, paths, classes, and symbols; inspect matching sections, not whole folders/files. Expand only to resolve a concrete gap; stop when outcome, scope, and affected artifacts are understood. Consult `.litespec/archived/` only to reconstruct a specific missing decision or rationale. Separate verified facts, assumptions, and unresolved decisions.
2. Explain outcome and scope; recommend an option when alternatives matter. Resolve continuity/compatibility under the specification contract. Apply the shared agreement rule; wait for answers only to unresolved material questions.
3. Capture the handoff beside the agreement in spec.md. Identify the observable outcome, its affected contract or entry point, the pattern another session can reuse, and any existing check that demonstrates success. For multiple outcomes, identify shared dependencies once. If a failure would be hard to detect, name the boundary and an example that would expose it. Leave unresolved decisions explicit.
4. Mark Explore confirmed when material questions are resolved. Leave grouping and assignment to Propose and keep the change draft.

For revisions to an existing active change, read and follow [incremental revision](../litespec-shared/revision.md) instead of restarting exploration. Do not implement.
