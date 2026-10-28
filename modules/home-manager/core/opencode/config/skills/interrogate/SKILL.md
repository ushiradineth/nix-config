---
name: interrogate
description:
  "Adversarially challenge a concrete change or executable design and verify findings. Use for
  contested designs, risky changes or an explicit adversarial review."
license: MIT
---

# Interrogate

State the change's intent and exact review scope, including relevant dirty work. Read the actual
diff. Stay read-only unless the user also requested fixes.

For an explicit adversarial attack or consequential risk, use two independent reviewers unless the
scope justifies another. A routine bounded fix can apply this rubric inline. Give reviewers the same
scope and intent, plus different failure angles where useful. Use configured models and state when
cross-model review is unavailable. Use separate scratch workspaces for repros. Reviewers must not
edit product files, post comments or launch agents.

Ask for a concrete failure mechanism, source location, exact command and actual versus required
output. Rerun each material reproduction and merge findings with the same root cause. Keep only
findings that violate the stated intent. No findings is valid.

A source-backed concern whose check cannot run stays explicitly unverified; never promote it to a
reproduced defect or hide its missing prerequisite. Drop speculation, preferences and risks that
need a future unrelated change. Report intent, verified findings, unverified limits, and the reason
for any disputed or dropped finding. Apply nothing during a review-only request.
