---
name: beam-search-execution
description:
  Use when one-pass iteration is likely to miss stronger solutions. Generate bounded variants, score
  them, and converge with explicit evidence.
---

# Beam search execution

## Trigger conditions

Use this skill when at least one is true:

- the task has multiple plausible approaches with meaningful tradeoffs
- correctness or quality depends on selecting among alternatives
- first-pass drafts keep requiring major rewrites

Do not use for trivial single-step fixes.

## Core rule

Generate multiple bounded variants, then select with explicit criteria and evidence.

## Workflow

1. Define constraints and non-goals before generating variants.
2. Generate `N` variants (default `3`, max `7`).
3. Score each variant on correctness, risk, effort, and reversibility.
4. Select one variant and justify rejection of others.
5. Run a thin-slice validation plan for the selected variant.
6. If selection confidence is low, run one focused re-beam on weak areas only.

## Output contract

Return:

1. `Constraints`: required boundaries and exclusions.
2. `Variants`: concise summary for each option.
3. `Score matrix`: criteria scores with evidence notes.
4. `Selection`: chosen option and reject rationale.
5. `Thin-slice validation`: first implementation step and verification.

## Anti-patterns

- unbounded variant generation with no selection discipline
- selecting by fluency instead of evidence
- re-generating full solutions when only one weak area needs refinement
