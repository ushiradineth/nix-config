---
description: Use when .agents context is bloated and needs safe compaction
agent: builder
---

Compact agent state using args: `$ARGUMENTS`.

Intent: preserve completed actions, active assumptions, IDs, tool outcomes, unresolved blockers, and
the next concrete goal while reducing stale context.

Target scope:

- `.agents/CONTEXT.md`
- `.agents/MEMORIES.md`
- `.agents/PROGRESS.md`
- `.agents/plans/*.md`
- `.agents/REMINDERS.md` when present

Success criteria:

- Active IDs and unresolved blockers are preserved.
- Duplicate or superseded entries are removed or merged without semantic drift.
- Shared language and operating-model material moves to `.agents/CONTEXT.md` instead of bloating
  memories or decisions.
- Open artifact-sync obligations remain visible.
- Ambiguous stale entries are reported instead of deleted.

Workflow:

1. Start with scoped shell discovery using `ls` and `rg` to locate relevant `.agents` files.
2. Read `.agents/CONTEXT.md` first when it exists, then read relevant memory, progress, plan, and
   reminder files.
3. Build a reference map of memory IDs, decision IDs, active plan IDs, open reminders, and blockers.
4. Move glossary terms, lane definitions, state-file rules, and durable operating rules into
   `.agents/CONTEXT.md` when they are repeated elsewhere.
5. Compact only entries that are clearly duplicate, stale, or superseded.
6. Summarize historically important but unreferenced context into concise archival bullets instead
   of dropping it silently.
7. Apply edits only to `.agents/*` unless explicitly asked to touch other files.
8. Use `artifact-coherence` guidance when material upstream or downstream drift is detected.

Output:

1. `Compacted`: files changed and reductions made.
2. `Preserved`: active IDs and critical context retained.
3. `Archived`: condensed historical bullets created.
4. `Context updates`: language, operating-model, or state rules moved to `.agents/CONTEXT.md`.
5. `Escalations`: ambiguous stale entries, reference conflicts, or blocked edits.
6. `Drift checks`: upstream vs downstream artifact coherence findings.

Stop rules:

- Never remove unresolved blockers, active reminders, or referenced IDs.
- Never use `.agents/CONTEXT.md` as a decision log or plan archive.
- Never rewrite security, deployment, or irreversible-operation decisions.
- If a rule conflicts with active references, preserve entries and report under `Escalations`.
