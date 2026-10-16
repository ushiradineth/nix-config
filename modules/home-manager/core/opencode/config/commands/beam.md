---
description: Generate bounded variants, score them, and select one direction
agent: planner
---

Apply `beam-search-execution` to `$ARGUMENTS` as an explicit planning-only override.

Use relevant evidence to compare genuinely distinct options, select the simplest useful direction,
and return the skill's constraints/variants/evaluation/selection/thin-slice output. Do not
manufacture alternatives for an obvious fix, optimize novelty, implement changes or launch another
agent.

Ask only if a missing constraint materially changes the selection; otherwise state the assumption.
