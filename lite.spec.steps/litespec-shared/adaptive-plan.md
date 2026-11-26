# Plan adaptive steps

Group related work by the outcome and impact it delivers. Record `Execution: <difficulty> | <owner>` with each step: in its step file, or beside an inline step in spec.md, never in the index table. Append `| review: <boundary>` when a sensitive boundary needs focused principal review.

Rate the decisions left after exploration. With a native `litespec-very-easy` profile in Codex or Claude Code, use `very-easy` for a mechanical change with explicit references and a direct check. Otherwise classify that work as `easy`. Easy follows a known pattern. Medium has bounded local decisions. Hard has unresolved technical strategy or integration. The principal owns medium and hard steps. Resolve open product decisions before dispatch.

For Very Easy or Easy, choose `executor` when a fresh worker can start from the step's references and existing evidence, deliver the whole outcome and demonstrate it with the planned checks. Choose `principal` when preparing and reviewing the handoff would take about as much work as the edit. A legacy reader default with its located fixture can be `easy | executor | review: old-format fixture`. A writer-format change with open local design is `medium | principal`.

Reassess the line and affected checks when revising a step. Keep model names out of specs.
