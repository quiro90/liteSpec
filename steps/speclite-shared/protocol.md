# Shared rules

Read once per context; reread if changed or unavailable in context. Keep this folder beside the four skills. Use available tools without requiring a provider.

- **Language:** use the user's language for communication and new specs; preserve existing documents' language. Keep paths, skill names, and state values unchanged.
- **Record:** resume the same change in `.liteSpec/<spec-name>/` from the project root; avoid collisions and reserved folders `docs`, `archived`, and `steps`. Record enough to continue without the conversation.
- **Agreement:** faithfully summarize Explore's actual question, user answer, and agreed scope in spec.md. Record implementation authorization and its scope separately; confirmation and ready status are not permission. Preserve valid agreements; never invent them.
- **States:** change = draft / ready / implementing / done; draft has material unknowns, ready is specified, implementing includes interrupted work, done requires closure. Step = pending / active / blocked / done, stored only in the index.
- **Freshness:** reuse findings; minimally check relevant sources before relying on them. If changed or uncertain, reread affected parts and update affected specs/checks, not the entire analysis.

## Output and reading contract

Keep only information that guides execution, prevents rediscovery, or verifies outcomes. Use concise bullets and concrete paths/symbols; omit empty sections, repeated context, transcripts, large code excerpts, and work logs. Brevity must not hide constraints or unresolved decisions.

**spec.md:** goal and scope limits; shared decisions/constraints; Explore agreement and authorization; observable overall acceptance; change state; step index. Each index row has a linked step, prerequisite step IDs (or none), and status. Include overall verification results and unresolved cross-step issues only when relevant.

**NN-short-name.md:** one independently verifiable outcome comprising related tasks, not one file per checkbox or source file. Include:
- Outcome.
- Necessary context: paths/symbols, local constraints/decisions and their non-obvious reasons. Label assumptions. Include the minimum interface expected from prerequisites so execution does not require reading their specs.
- Concrete checkbox tasks, including affected documentation when needed.
- Observable acceptance and how to check it.
- On execution: actual checks/results; if unfinished, remaining work/blocker and next action. Replace stale continuation notes.

Shared facts belong in spec.md; local details belong in their step. For a small single-step change, inline the step in spec.md and omit the index and extra file. During Explore, keep useful findings in spec.md; Propose moves local findings into steps. Add linked notes only for substantial, necessary detail; state when to read them and do not duplicate it.

**Read selectively:** read spec.md plus the selected step and relevant code. Load notes or other steps only to resolve a specific missing detail. For all steps, load each when reached; never preload every step by default.

## Incremental revision

Use this procedure when the user changes an active change or relevant files differ from recorded findings; speclite-modify is its explicit entry point. Archived changes stay immutable: create a linked new change through Explore.

1. Read spec.md, the current or directly affected step, and only the requested delta or relevant changed source sections. Use recorded paths/symbols and targeted searches; do not reload all steps, docs, or project files. Expand only to resolve a concrete missing detail or a changed dependency contract.
2. A clear user decision updates the agreement without repeat confirmation; a suggestion is not a decision, and an edited file is not proof of user intent. Resolve technical adjustments within agreed behavior and authorization. Ask only unresolved material questions about scope, behavior, acceptance, or conflicting edits; preserve user edits and pause affected work until answered. Continue independent authorized work.
3. Replace obsolete decisions, context, tasks, acceptance, and prerequisite interfaces in spec.md and affected steps; preserve valid agreements and authorization, checking whether it covers the revised work. Add or remove steps only as needed and keep prerequisites acyclic. Follow dependents only where their assumptions or checks are invalidated, including already completed steps; stop propagation at unchanged contracts.
4. Reopen affected done steps as pending (blocked if awaiting an answer); invalidate only affected checkboxes and verification results. Preserve unaffected progress. Keep implementing if execution has begun, recording unresolved questions as blockers; otherwise use draft while material questions remain, ready when specified. Record only remaining work/blocker and next action, not a revision log. Recheck affected acceptance and integration before closure; update affected maintained docs when their behavior is verified. Updating a spec alone does not authorize implementation.

## Closure

**Living documentation:** before archiving, create or update `.liteSpec/docs/index.md` and small topic notes in `.liteSpec/docs/`. Paths are relative to the project root. Obsidian compatibility means Markdown and relative links, not an external vault or vault configuration; an alternate destination requires explicit user direction. Index each topic with a link and one-line purpose. Read only the index and affected topics; document verified current behavior, purpose, final decisions with non-obvious reasons, key paths/symbols and their roles, and necessary constraints. Keep concise bullets and sufficient context for future work. Reuse notes by stable topic, not by spec; split only when topics warrant separate reading. Replace obsolete facts; omit empty sections, duplicated content, task lists, implementation logs, and obvious code details. Keep docs outside archived change folders. Update other affected maintained documentation; link rather than duplicate authoritative detail. Preserve archived history and link superseded specs. Record unavailable required updates as pending.

Verify the documentation index exists, its affected topic links resolve, and those notes reflect the verified implementation. Existing accurate notes need no rewrite. Record the documentation paths checked and a brief result in spec.md; missing required documentation blocks closure, even when code checks pass. Report the documentation and archive paths at completion.

Close only after all steps, overall acceptance, required checks and documentation are complete. Record overall verification, mark done, and move the whole folder to `.liteSpec/archived/<YYMMddHHmm>-<spec-name>/` using local closure time. Overwrite nothing; leave no active copy. If moving fails, record and report incomplete closure. Later changes get a new spec.
