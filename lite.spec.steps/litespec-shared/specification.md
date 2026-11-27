# Specification contract

**spec.md:** goal/scope limits; shared decisions/constraints and continuity policy; Explore agreement and authorizations; observable overall acceptance; change state; step index. Each row links a step and lists prerequisite IDs (or none) and status. Keep global verification and cross-step blockers/next actions here; local continuation stays in its step.

**Continuity (every spec):** use one or two lines naming `preserve` (retain), `extend` (add while retaining), `replace` (supersede), or `new` (no predecessor), with concrete boundaries. Add compatibility `required`, `breaking-approved`, or `not-applicable`, identifying interfaces, formats, requirements, or consumers to preserve. Name removals/migrations when needed; steps add only local exceptions. This covers code, documents, and other artifacts. Tags never authorize deletion or breakage. Resolve material uncertainty before affected work; do not invent approval or preservation/removal requirements. Missing policies need targeted clarification, not renewed exploration.

**NN-short-name.md:** one independently verifiable outcome, not one file per task or source. Include:
- Outcome and consumer-visible result. Group the implementation, regression example and required documentation that deliver this outcome. Split when the next group has a separately testable result or consumes a prerequisite contract.
- Cite existing paths/symbols located in the project or identified by the user. Mark planned additions as new. Record local constraints, decisions and non-obvious reasons; label assumptions. State prerequisite interfaces sufficient to avoid reading their specs.
- Checkbox tasks, including explicit documentation deliverables. Make a living-doc update a task when the user requests it as part of the delivery, or when other work or sessions will rely on a settled flow or contract before closure; otherwise Archive consolidates.
- Observable acceptance and methods, including a concrete input and expected result where useful. Agree the behavior and identify the checks before editing. Distinguish required checks, optional tests, and user-run checks.
- In Adaptive, the execution line under the [planning rule](adaptive-plan.md).
- Actual checks/results; remaining work/blocker and next action. Replace stale continuation notes.
- Once done, `Docs:` with the target topic and 1-3 durable facts (verified behavior, decision and reason, key paths/symbols), or `Docs: none`.

Shared facts belong in spec.md; local details in steps. Inline small single-step changes in spec.md without an index or extra file. Explore records useful findings there; Propose moves local findings into steps. Add notes only for substantial necessary detail, with a reading trigger and no duplication.
