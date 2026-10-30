---
name: speclite-modify
description: Revise an active SpecLite change when user decisions or relevant source files change, preserving unaffected context and progress.
---

Read the [shared rules](../speclite-shared/protocol.md) and [incremental revision](../speclite-shared/revision.md).

1. Identify the active change and requested or detected delta. If ambiguous, ask which change or decision is intended; do not infer it from unrelated edits. For an archived change, create a linked new change through speclite-explore.
2. Follow incremental revision: inspect only affected context, resolve missing decisions, and update the existing spec and affected steps. Do not restart valid Explore/Propose work or create a separate revision record.
3. Briefly report the revised decisions, affected steps/checks, and any blocker. Continue through speclite-apply only when implementation is requested or already authorized and the affected work is unblocked; a specification-only request stops here.
