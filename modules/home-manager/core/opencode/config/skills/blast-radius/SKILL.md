---
name: blast-radius
description:
  "Find cross-boundary breakage beyond a diff and prove the key fact that makes the change safe. Use
  for blast radius or what could this break."
license: MIT
---

# Blast radius

Read the scoped diff, its changed contract and affected callers. Find the one or two facts the
change's safety actually depends on. A caller list alone is not an impact analysis.

Follow what text search misses: serialized data, configuration, persistent state, retries and
cleanup, generated consumers, another language reading the same bytes, pinned library semantics and
lifecycle ordering. Inspect the dependency version and local patches when relevant.

Prove the key safety fact through the cheapest meaningful native test, consumer command or running
flow. Keep any probe in the component's language and use the real implementation. Do not invent a
foreign assertion harness or repeat source strings as a test.

Report what changes, the safety fact and its proof level, confirmed breakage, cases checked and
cleared, and anything still unproven. Give real source locations and commands. Do not manufacture
probabilities. Use an independent `reviewer` for consequential blind spots when the cost is
justified. A review-only request does not authorize product edits or an external publication.
