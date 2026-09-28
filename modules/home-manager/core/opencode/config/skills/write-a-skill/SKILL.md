---
name: write-a-skill
description:
  Use when creating, revising, or evaluating skills, prompts, AGENTS.md, CLAUDE.md, or other
  agent-consumed instructions.
---

# Write a skill

## Core rule

Spend as little always-loaded context as possible while making the required behavior predictable.

A context pointer is a short reference that names what to load and the distinct branches that should
trigger it. Pointer wording controls discovery, so keep one trigger per real branch and remove
synonyms that describe the same case.

## Workflow

1. Capture the task, trigger branches, near misses, output, and required evidence.
2. Find the source of truth. Treat discoverable config, scripts, and directory layout as the
   environment, not prose to cache unless the lookup is genuinely expensive.
3. Place information at the lowest useful level:
   - in-file steps for actions every run needs
   - in-file reference for rules consulted within most runs
   - disclosed reference behind a context pointer for branch-specific detail
4. Give every step a checkable completion criterion. State both the observable bound and the amount
   of legwork required.
5. Prune duplicate meanings, stale caches, and no-op instructions that do not change model behavior.
6. Validate the instruction against realistic trigger and near-miss prompts.

## Skill-specific rules

- `name` uses lowercase words and hyphens.
- `description` starts with `Use when` and names trigger conditions, not the full workflow.
- Keep the main body concise. Use `references/` for heavy branch-specific guidance and `scripts/`
  for deterministic helpers.
- Keep one source of truth for each behavior. A pointer may repeat a leading term, but not the full
  rule it points to.

## Quality checklist

- Trigger branches and near misses are explicit.
- Every step has a completion criterion.
- Progressive disclosure keeps branch-specific reference out of the main path.
- Environment facts are not duplicated as a stale cache.
- No-op and duplicate instructions are removed.
- The validation path proves both invocation and output behavior.
