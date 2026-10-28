---
name: ketchup
description:
  "Give a read-only catch-up on work since the user's previous message and list real decisions
  waiting on them."
license: MIT
---

# Ketchup

Catch the user up from the last user-authored message before this request. Notifications and worker
reports are not user messages. Include still-pending decisions from earlier in the task.

Keep status gathering read-only. Use the conversation, existing artifacts and fresh status for
touched PRs or jobs. Do not edit code, launch an app, start a new job or post anything while
gathering status.

Open with what waits on the user, or say nothing does. Explain what changed for them, what is done,
what is still running and what failed or remains unchecked. Keep it short without dropping separate
action items.

For each real decision, give the options, your recommendation, evidence, consequence and relevant
link. Work you can still complete yourself is not an action item. Do not invent a decision or ask
for approval that was already granted.

Reuse existing screenshots or small diagrams only when they clarify the result. Do not fabricate a
visual or force one for a status list. Link only artifacts that exist. When this is a status
interruption during authorized work, answer and resume unless the user asked to pause.
