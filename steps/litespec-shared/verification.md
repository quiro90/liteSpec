# Verification

Check selected tasks/steps against acceptance, required docs, and prerequisite contracts. Whole-change checks also inspect every step's evidence, overall acceptance, integration, and continuity/compatibility. Load steps as needed; group related checks.

**Types:** code/artifact quality and consistency review does not automatically request automated or manual tests. Run authorized required tests. Offer useful optional tests once: whether to run them, and by agent or user; reuse decisions. For user-run checks, provide brief steps/expected results and request outcomes; label them user-reported, not agent-verified.

**Evidence:** record method/command, result, and relevant source revision/conditions beside the work; global results go in spec.md. Reuse while sources, dependencies, and conditions remain valid. Inspect uncertain inputs; repeat only missing/invalidated checks unless asked to rerun. Document consistency does not prove functional correctness.

**Progress:** update checkboxes from evidence. Mark a step done only after all required tasks, prerequisites, acceptance, checks, and docs pass; partial checks cannot complete it. Reopen invalidated done steps as pending, or blocked if unable to proceed. Invalidate affected global evidence; reset existing closure to `pending-verification` for failed/pending required checks. Required checks remain pending until completed or explicitly dropped from scope; declined optional tests never block completion. Preserve unaffected progress; replace stale notes with remaining work/blocker and next action.

Verification alone neither fixes nor closes changes. Keep change state; route scope revisions or implementation findings to the appropriate skill.
