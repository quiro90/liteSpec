---
name: litespec-apply
description: Execute authorized LiteSpec steps and verify outcomes without archiving.
---

Read the [shared rules](../litespec-shared/protocol.md).

1. On direct entry, locate the requested change. If the request is to implement new work without an active spec, run Explore then Propose under the same parent before editing. For an existing change read spec.md and fill only the missing stage. Require confirmed Explore, ready/implementing state and implementation authorization covering this work.
2. Execute requested steps or authorized pending work in dependency order. Complete prerequisites first if authorized; otherwise report blockers.
   On resuming, inspect any already-active step before starting another writer, including after a mode switch. Use the recorded owner or native handle to rejoin a running worker and wait. If its state is unknown, seek confirmation that it stopped before editing or redispatching. Once stopped, reconcile the actual diff, checks and remaining scope; verify completed work and continue only what remains.
3. Before editing, compare the current step's inputs and acceptance to the recorded contract. Mark implementing and the step active. In Classic the principal executes the step. In Adaptive use [adaptive execution](../litespec-shared/adaptive-apply.md) for the current step. Include required documentation. On a changed contract follow [incremental revision](../litespec-shared/revision.md).
4. Follow [verification](../litespec-shared/verification.md) per step. Check remaining tasks/evidence; once all steps finish, verify the whole change.
5. Report blockers/next action or readiness for litespec-archive. Keep implementing; invoke Archive separately for living-doc consolidation and archiving.
