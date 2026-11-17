# Specification contract

**spec.md:** goal/scope limits; shared decisions/constraints and continuity policy; Explore agreement and authorizations; observable overall acceptance; change state; step index. Each row links a step and lists prerequisite IDs (or none) and status. Keep global verification and cross-step blockers/next actions here; local continuation stays in its step.

**Continuity (every spec):** use one or two lines naming `preserve` (retain), `extend` (add while retaining), `replace` (supersede), or `new` (no predecessor), with concrete boundaries. Add compatibility `required`, `breaking-approved`, or `not-applicable`, identifying interfaces, formats, requirements, or consumers to preserve. Name removals/migrations when needed; steps add only local exceptions. This covers code, documents, and other artifacts. Tags never authorize deletion or breakage. Resolve material uncertainty before affected work; do not invent approval or preservation/removal requirements. Missing policies need targeted clarification, not renewed exploration.

**NN-short-name.md:** one independently verifiable outcome, not one file per task or source. Include:
- Outcome.
- Necessary paths/symbols, local constraints/decisions and non-obvious reasons; label assumptions. State prerequisite interfaces sufficient to avoid reading their specs.
- Checkbox tasks, including explicit documentation deliverables; living-doc consolidation belongs to Archive.
- Observable acceptance and methods; distinguish required checks, optional tests, and user-run checks.
- Actual checks/results; remaining work/blocker and next action. Replace stale continuation notes.

Shared facts belong in spec.md; local details in steps. Inline small single-step changes in spec.md without an index or extra file. Explore records useful findings there; Propose moves local findings into steps. Add notes only for substantial necessary detail, with a reading trigger and no duplication.
