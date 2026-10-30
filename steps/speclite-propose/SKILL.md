---
name: speclite-propose
description: Turn confirmed SpecLite exploration into a minimal index and executable steps. Does not implement code.
---

Read the [shared rules](../speclite-shared/protocol.md) and [specification contract](../speclite-shared/specification.md).

1. Read spec.md and only relevant findings. Require recorded Explore confirmation; if missing or invalid, complete speclite-explore first.
2. Build the fewest coherent, verifiable steps under the specification contract. Carry continuity constraints into affected tasks and acceptance, including authorized removal/migration.
3. Record explicit prerequisites without cycles; order steps accordingly.
4. For revised decisions or source discrepancies, read and follow [incremental revision](../speclite-shared/revision.md), preserving implementing state if execution has begun. Otherwise keep draft while material definitions are missing, ready when specified. Never treat assumptions as agreements.

Continue with speclite-apply only when implementation is authorized.
