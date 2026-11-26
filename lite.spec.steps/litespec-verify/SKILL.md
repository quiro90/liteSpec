---
name: litespec-verify
description: Verify selected LiteSpec tasks, steps, or a whole active change without implementing fixes or archiving.
---

Read the [shared rules](../litespec-shared/protocol.md) and [verification rules](../litespec-shared/verification.md).

1. Identify the active change and requested checks; ask only if ambiguous. Read spec.md, then selected steps and necessary sources. Without a narrower request, verify the change.
2. On direct entry without an identifiable spec or acceptance, report the missing reference or criterion and stop. Never dispatch an implementation worker, even for an executor-owned step.
3. For each selected outcome, compare the accepted behavior, actual scope and evidence under the shared verification rules. Run only outstanding required checks or explicitly requested reruns. Record reused evidence by reference, newly observed results and the next action.
4. Report failures or pending checks with their location and next action, or a brief success summary. Update only verification records (including `Docs:` lines), checkboxes, and status; do not fix artifacts, revise agreements, or archive.
