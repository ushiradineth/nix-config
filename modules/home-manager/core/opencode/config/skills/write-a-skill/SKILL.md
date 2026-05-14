---
name: write-a-skill
description:
  Use when creating, revising, or evaluating an agent skill, including skill descriptions, trigger
  behavior, progressive disclosure, and bundled resources.
---

# Write a skill

## Core rule

Skills should be small, triggerable, and reusable. The description decides whether the skill loads.

## Workflow

1. Capture intent:
   - task or domain
   - trigger phrases and near misses
   - expected output
   - scripts or references needed
2. Draft `SKILL.md`:
   - `name` uses lowercase words and hyphens
   - `description` starts with `Use when` and names trigger conditions
   - body gives the smallest useful workflow
3. Add resources only when they save repeated work:
   - `references/` for heavy guidance
   - `scripts/` for deterministic helpers
4. Review against realistic prompts before treating it as done.

## Quality checklist

- Description is trigger-focused, not a workflow summary.
- Body is concise and scannable.
- Skill does not duplicate an existing skill.
- References are one level deep unless there is a strong reason.
- Validation path is explicit.
