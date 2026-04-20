---
name: artifact-coherence
description:
  Use when decisions span multiple artifacts and drift risk is high. Keep source-of-truth and
  downstream outputs synchronized.
---

# Artifact coherence

## Trigger conditions

Use this skill when at least one is true:

- upstream strategy or plan artifacts exist and downstream execution artifacts are being edited
- numeric values, constraints, or decision rationale changed during implementation
- output quality depends on cross-artifact consistency

## Core rule

Treat source-of-truth artifacts as infrastructure. Update them when downstream work changes the
underlying decision.

## Workflow

1. Identify source-of-truth artifacts in scope.
2. Identify downstream artifacts that consume or reference those decisions.
3. Compare key facts, constraints, and rationale across artifacts.
4. Record drift severity: `none`, `minor`, or `material`.
5. Apply updates in coherence-preserving order, upstream first.
6. Verify references and values are synchronized after updates.

## Output contract

Return:

1. `Artifact map`: upstream and downstream files.
2. `Drift findings`: mismatch, severity, and impact.
3. `Update order`: exact sequence to restore coherence.
4. `Verification`: checks proving synchronization.

## Anti-patterns

- updating downstream artifacts while leaving upstream source-of-truth stale
- changing decision meaning in one artifact without propagating it
- declaring coherence without explicit cross-file verification
