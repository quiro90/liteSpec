---
name: speclite-explore
description: Inspect a SpecLite change and confirm its intended outcome with the user before specification or implementation.
---

Read the [shared rules](../speclite-shared/protocol.md).

1. Read applicable AGENTS.md. Start with `.liteSpec/docs/index.md` and relevant topic notes if present, then other relevant documentation; verify findings against targeted code. Search by goal keywords, paths, classes, and symbols; inspect matching sections, not whole folders/files. Expand only to resolve a concrete gap; stop when outcome, scope, and affected code are understood. Consult `.liteSpec/archived/` only to reconstruct a specific missing decision or rationale. Separate verified facts, assumptions, and unresolved decisions.
2. Explain outcome and scope; recommend an option when alternatives matter. Ask about unresolved scope, behavior, or acceptance; if clear, ask for confirmation of your concise understanding. Wait for an actual answer, even after a direct implementation request.
3. Record the agreement in spec.md, plus only findings needed for specification or implementation. Mark Explore confirmed only when material questions are resolved; otherwise record what remains. Keep the change draft for Propose.

For revisions to an existing active change, follow shared incremental revision rules instead of restarting exploration. Do not implement. Reuse recorded confirmation across sessions unless agreed scope or behavior changes; do not repeat valid confirmation.
