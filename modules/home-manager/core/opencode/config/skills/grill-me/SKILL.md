---
name: grill-me
description:
  Use when a plan, design, or implementation request has ambiguity that could change scope,
  architecture, acceptance criteria, safety, or validation.
---

# Grill me

## Core rule

Interview only when the answer matters. Ask one decisive question at a time and include your
recommended answer.

## Workflow

1. Explore first when the answer is available in code, docs, git history, or existing state.
2. Name the decision branch the question controls.
3. Ask one question.
4. Provide a recommended answer and why.
5. Continue when the user answers, or record a safe assumption when the ambiguity is not critical.

## Good question shape

```md
Question: Should this stay prompt-only, or should it also change runtime permissions?
Recommendation: Prompt-only for now because runtime permission changes are higher risk and the
current issue is behavioral. Why it matters: This decides whether builder edits `prompts/*.md` only
or also touches `opencode.json`.
```

## Stop conditions

- Stop and ask when proceeding could build the wrong thing.
- Do not ask preference questions that do not affect implementation.
- Do not batch many questions unless the user asks for a questionnaire.
