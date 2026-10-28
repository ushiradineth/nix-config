---
name: architect
description:
  "Settle consequential ownership, interface or state-model decisions from the caller's usage before
  implementation."
license: MIT
---

# Architect

Trace the existing behavior and callers with `how`. Write the intended usage first, then the domain
types, invariants, signatures and ownership. Favor the shape that deletes repeated rules and hidden
state. Make invalid combinations unrepresentable where the language permits it.

For a consequential unsettled choice, compare genuinely different shapes. Use a small prototype for
an observable question, or `arena` when independent attempts would expose useful alternatives. A
routine extension with an obvious existing owner needs only a short inline sketch.

Choose from evidence and explain the tradeoff. Implement in the current session when the request
includes implementation. A request for design only, or an explicit checkpoint, stops at the sketch.
If implementation requires repeated casts, scattered workaround guards or duplicated state, revisit
the model instead of defending the sketch.
