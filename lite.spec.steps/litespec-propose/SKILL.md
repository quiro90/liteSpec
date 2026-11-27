---
name: litespec-propose
description: Turn confirmed LiteSpec exploration into a minimal index and executable steps. Does not implement code.
---

Read the [shared rules](../litespec-shared/protocol.md) and [specification contract](../litespec-shared/specification.md).
Read the [delegation rules](../litespec-shared/delegation.md) before gathering evidence.

1. Read spec.md and only relevant findings. Require recorded Explore confirmation; if missing or invalid, complete litespec-explore first.
2. Build the fewest independently verifiable steps under the specification contract. Carry continuity constraints into affected tasks and acceptance, including authorized removal/migration.
3. Record explicit prerequisites without cycles; order steps accordingly.
   In Adaptive, rate each step under [adaptive planning](../litespec-shared/adaptive-plan.md).
4. For revised decisions or source discrepancies, read and follow [incremental revision](../litespec-shared/revision.md), preserving implementing state if execution has begun. Otherwise keep draft while material definitions are missing, ready when specified. Never treat assumptions as agreements.

Continue with litespec-apply only when implementation is authorized.
