# Plan adaptive steps

Record `Execution: <difficulty> | <owner>` with each step: in its step file, or beside an inline step in spec.md, never in the index table. Append `| review: <boundary>` when a sensitive boundary needs focused principal review, even in an Easy step.

Rate the decisions left after exploration. Easy follows a known pattern; medium has bounded local decisions; hard has unresolved technical strategy or integration. The principal owns medium and hard steps. Resolve open product decisions before dispatch.

Choose `easy | executor` when a fresh worker can start from the step's references and existing evidence, deliver the whole outcome and demonstrate it with the planned checks. Choose `easy | principal` when preparing and reviewing the handoff would take about as much work as the edit. Example: a legacy reader default with its located fixture is `easy | executor | review: old-format fixture`; a writer-format change with open local design is `medium | principal`.

Reassess the line and affected checks when revising a step. Keep model names out of specs.
