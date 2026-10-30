# Shared rules

Read each rules file once per context; reread if changed or unavailable. Load only references required by the current skill and situation, not this entire folder. Use available tools without requiring a provider.

- **Language:** use the user's language for communication and new specs; preserve existing documents' language. Keep paths, skill names, state values, and policy tags unchanged.
- **Record:** resume the same change in `.litespec/<spec-name>/` from the project root; avoid collisions and reserved folders `docs`, `archived`, and `steps`. Record enough to continue without the conversation.
- **Agreement:** faithfully summarize Explore's actual question, user answer, and agreed scope in spec.md. Record implementation and archive authorization with their scopes separately; scope confirmation and ready status authorize neither. Preserve valid agreements; never invent them.
- **States:** change = draft / ready / implementing / done; draft has material unknowns, ready is specified, implementing includes interrupted work, done requires closure. Step = pending / active / blocked / done, stored only in the index.
- **Freshness:** reuse findings; minimally check relevant sources before relying on them. If changed or uncertain, reread affected parts and update affected specs/checks, not the entire analysis.

## Minimal context

Keep only information that guides execution, prevents rediscovery, or verifies outcomes. Use concise bullets and concrete paths/symbols; omit empty sections, repeated context, transcripts, large code excerpts, and work logs. Prefer one-line fields and linked references over repeated explanations or extra files; do not copy this protocol into generated artifacts. Brevity must not hide constraints or unresolved decisions.

**Read selectively:** read spec.md plus the selected step and relevant source material. Load notes or other steps only to resolve a specific missing detail. For all steps, load each when reached; never preload every step by default.
