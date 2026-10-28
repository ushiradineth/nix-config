---
name: figure-it-out
description:
  "Design and execute a verifiable workflow for a large migration, unfamiliar multi-part task or
  unattended run that no shorter playbook fits."
license: MIT
---

# Figure it out

Ground the task first. State the falsifiable finish condition, scope, constraints and actual
blockers. Choose rigor by consequence and uncertainty. A clear authorization to rewrite is not a
reason to preserve compatibility phases or ask for design approval again.

Design a short phase list, riskiest unknown first. Establish the baseline and a way to verify before
large edits. Use `architect` for unsettled ownership or interfaces and prototypes for empirical
questions. Reuse a settled design. Present the phase list, then execute without waiting unless an
approval gate was requested.

Each coherent unit is a hypothesis: change, verify the real artifact, keep what advances the goal,
and remove unsuccessful experiments without discarding unrelated work. Use `swarm` only for
independent slices. Keep coupled implementation under one owner.

For long or unattended work, use `show-me-your-work` for decisions, evidence and resume points.
Honor the agreed stopping condition; do not relax it to claim success. If blocked, preserve progress
and name the exact missing prerequisite. Finish by checking the whole against the original goal.

An unattended loop needs a native supported wake mechanism and explicit scope. OpenCode can use the
existing `oc-loop` CLI when the user requests an ongoing run; inspect its installed `--help` for
session, bounds and controls. Do not emulate Cursor's /loop, silently start a daemon, auto-approve
new authority, or claim that one assistant turn can keep working after the process stops.
