---
description: Detect and resolve upstream-downstream artifact drift
agent: builder
---

Apply `artifact-coherence` inline to `$ARGUMENTS` as an explicit scoped override.

Return the skill's artifact map, drift severity, source-first update order and verification
evidence. Update only artifacts covered by the request/accepted authority; do not silently change
source intent, launch another agent or pull unrelated systems into synchronization.

If source-of-truth intent conflicts with implementation, stop for the material decision before
edits.
