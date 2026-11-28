# Step contract

**NN-short-name.md:** one independently verifiable outcome, not one file per task or source. Include:
- Outcome and consumer-visible result. Group the implementation, regression example and required documentation that deliver this outcome. Split when the next group has a separately testable result or consumes a prerequisite contract.
- Cite existing paths/symbols located in the project or identified by the user. Mark planned additions as new. Record local constraints, decisions and non-obvious reasons; label assumptions. State prerequisite interfaces sufficient to avoid reading their specs.
- Checkbox tasks, including explicit documentation deliverables. Make a living-doc update a task when the user requests it as part of the delivery, or when other work or sessions will rely on a settled flow or contract before closure; otherwise Archive consolidates.
- Observable acceptance and methods, including a concrete input and expected result where useful. Agree the behavior and identify the checks before editing. Distinguish required checks, optional tests, and user-run checks.
- In Adaptive, the execution line under the [planning rule](adaptive-plan.md).
- Actual checks/results; remaining work/blocker and next action. Replace stale continuation notes.
- Once done, `Docs:` with the target topic and 1-3 durable facts (verified behavior, decision and reason, key paths/symbols), or `Docs: none`.
