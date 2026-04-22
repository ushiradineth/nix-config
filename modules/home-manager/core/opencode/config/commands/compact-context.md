---
description: Use when .agents context is bloated and needs safe compaction
agent: builder
---

Compact agent state using args: `$ARGUMENTS`.

Use this command to reduce `.agents` context size while preserving active work, referenced IDs, and
high-signal history.

Target scope:

- `.agents/MEMORIES.md`
- `.agents/PROGRESS.md`
- `.agents/plans/*.md`
- `.agents/REMINDERS.md` when present

Workflow:

1. Start with scoped shell discovery (`ls`, `rg`) to locate relevant `.agents` files.
2. Use targeted reads to gather exact context before any edits.
3. If context looks stale or incomplete, rerun discovery and verify paths before continuing.
4. Read all relevant state files before any edits.
5. Build a reference map of active IDs:
   - memory IDs (`M-xxxx`)
   - decision IDs (`D-xxxx`)
   - active plan IDs (`P-YYYYMMDD-*` with `outcome: partial|blocked` or unchecked tasks)
   - open reminders and unresolved blockers
6. Apply compaction rules:
   - Keep all entries referenced by active plans, open reminders, or unresolved blockers.
   - Keep durable repo constraints and non-obvious facts that prevent rediscovery.
   - Remove duplicate bullets and stale superseded entries.
   - Merge repetitive bullets when meaning is unchanged.
   - Preserve ID integrity for every kept item.
   - Never delete IDs still referenced elsewhere.
   - Preserve file conventions (dense bullets, no long prose).
   - Preserve source-of-truth links between upstream artifacts and downstream execution notes.
   - If downstream decisions changed while upstream source-of-truth text stayed stale, keep both
     references and flag drift under `Escalations`.
   - Never compact away open artifact-sync obligations tied to active plans or unresolved blockers.
7. If compaction would remove historically important but unreferenced context, summarize it into one
   concise archival bullet instead of dropping it silently.
8. Apply edits only to `.agents/*` state files unless explicitly asked to touch other files.
9. If stale vs active cannot be decided confidently, keep the entry and flag it for escalation.
10. When material upstream or downstream drift is detected, use `artifact-coherence` guidance before
    finalizing compaction decisions.

Output contract:

Always return all sections:

1. `Compacted`: files changed and exact reductions made.
2. `Preserved`: active IDs and critical context intentionally retained.
3. `Archived`: condensed historical bullets created during compaction.
4. `Escalations`: ambiguous stale entries, reference conflicts, or blocked edits.
5. `Drift checks`: upstream vs downstream artifact coherence findings.

Safety gates:

- Never remove unresolved blockers, active reminders, or currently referenced IDs.
- Never rewrite semantics of security, deployment, or irreversible-operation decisions.
- Never reinterpret an ID to a new meaning to make compaction easier.
- If a rule conflicts with active references, preserve entries and report under `Escalations`.
