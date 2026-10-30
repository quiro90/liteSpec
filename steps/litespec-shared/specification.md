# Specification contract

**spec.md:** goal and scope limits; shared decisions/constraints and continuity policy; Explore agreement and authorizations; observable overall acceptance; change state; step index. Each index row has a linked step, prerequisite step IDs (or none), and status. Include overall verification results and unresolved cross-step issues only when relevant.

**Continuity policy (every spec):** record `preserve` (retain existing behavior/content), `extend` (add while retaining it), `replace` (supersede specified material), or `new` (no predecessor), followed by the concrete boundary. Add compatibility `required`, `breaking-approved`, or `not-applicable`, naming interfaces, formats, requirements, or consumers that must remain valid. Name removals/migrations only when needed. Use one or two lines in spec.md; steps add only local exceptions. These apply to code, documents, scripts, and other artifacts. A tag alone never authorizes deletion or breakage. Resolve material uncertainty before affected execution; do not invent approval or preservation/removal requirements. Existing specs missing this policy need only a targeted clarification, not full re-exploration.

**NN-short-name.md:** one independently verifiable outcome comprising related tasks, not one file per checkbox or source file. Include:
- Outcome.
- Necessary context: paths/symbols, local constraints/decisions and their non-obvious reasons. Label assumptions. Include the minimum interface expected from prerequisites so execution does not require reading their specs.
- Concrete checkbox tasks, including affected documentation when needed.
- Observable acceptance and how to check it.
- On execution: actual checks/results; if unfinished, remaining work/blocker and next action. Replace stale continuation notes.

Shared facts belong in spec.md; local details belong in their step. For a small single-step change, inline the step in spec.md and omit the index and extra file. During Explore, keep useful findings in spec.md; Propose moves local findings into steps. Add linked notes only for substantial, necessary detail; state when to read them and do not duplicate it.
