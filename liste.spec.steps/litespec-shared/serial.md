# Optional single active change per checkout

The project opts in by creating the directory `.litespec/serial/`. All LiteSpec parent sessions in this checkout follow this rule, in every mode. Workers operate under the parent's ownership.

Before any skill starts work on a change, atomically create the child directory `.litespec/serial/busy` (plain `mkdir` without `-p` on POSIX or `New-Item -ItemType Directory -ErrorAction Stop` without `-Force` in PowerShell). Only success grants ownership. On contention report the current owner if available and yield without polling or editing. On other errors report the error. Immediately record the session and intended spec in a small owner note inside busy. Nested phases in the owning invocation reuse the claim.

While holding the claim, check active directories in `.litespec/specs/` before creating or resuming work. If another change exists, report it and yield. If opt-in found multiple pre-existing changes, allow resuming those one at a time through archival; refuse new ones. Never archive automatically to free a slot.

Keep the claim while a worker is running. Release your own note and empty busy directory at the end of the invocation, including before yielding for user input. Reacquire and recheck before resuming. The active spec remains the reservation between invocations until archived. After a crash, a user may clear a stale busy directory only after confirming its owner and workers have stopped. Never steal a claim based on age. This cooperative rule covers sessions sharing this checkout.
