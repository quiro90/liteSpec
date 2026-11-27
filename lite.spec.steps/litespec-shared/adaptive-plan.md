# Plan adaptive steps

Resolve local decisions from available evidence. Give each step one checkable outcome. Extract a group of related easy or medium tasks when it delivers a separately testable result, even within a larger feature. Record its ID as a prerequisite wherever later work uses it.

Write exactly one level in the step file or beside an inline step in spec.md: `Execution: easy`, `Execution: medium` or `Execution: hard`. Add `| review: <boundary>` only for focused review. Keep model names out of the spec.

- `easy` — Mechanical edits or commands with explicit references and a direct check.
- `medium` — Logic with defined behavior, interfaces and a check that demonstrates the result. Internal implementation choices and changes across layers fit here.
- `hard` — A remaining decision can change behavior, an integration contract or technical strategy. Isolate the decision and record what will settle it. Ask the user about open product choices.

Once a decision is settled, record it and rate the remaining work before implementation. Add any missing acceptance check while planning.
