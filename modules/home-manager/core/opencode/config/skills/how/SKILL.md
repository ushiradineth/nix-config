---
name: how
description:
  "Trace how code works, including runtime flow, data types, ownership and affected callers.
  Read-only unless the caller separately requests implementation."
license: MIT
---

# How

Read the question's actual source before editing. For a narrow helper, inspect it and its callers
inline. For a large subsystem, partition a few read-only investigations only when they save context
or reveal independent paths; do not spawn an explainer just to rewrite your own findings.

Follow input to output, state transitions, error paths, persistence and cleanup. Inspect the pinned
dependency implementation when its semantics decide the answer. Use history for motivation and
separate that evidence from inference.

Explain the flow, key types, ownership and non-obvious constraints with real source locations.
Include only sections useful to the question. Name missing evidence. A question alone authorizes no
implementation. When called inside an implementation playbook, return to that playbook.
