---
description: Run an inline adversarial review against current output
agent: builder
---

Apply `adversarial-self-play` inline to `$ARGUMENTS` as an explicit review-only override.

Pin the artifact/expected behavior, challenge relevant correctness/security/reliability assumptions,
and return the skill's attack evidence, findings, mitigation requirements and readiness impact. Do
not launch a task, reviewer or slash command, and do not mutate the artifact without approval.

Unresolved Critical/Important findings block readiness; explain the smallest fix and verification
path. Keep unrelated artifacts and hypothetical infrastructure changes outside the review.
