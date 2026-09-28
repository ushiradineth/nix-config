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

Model unresolved choices as a decision tree. The frontier is the next decision whose prerequisites
are settled. Work one frontier question at a time so later questions do not assume an unanswered
choice.

## Workflow

1. Map the known decisions, unresolved branches, and their prerequisites.
2. Separate facts from decisions. Find facts in code, docs, git history, tools, or existing state.
   Ask the user only for decisions that require their intent or judgement.
3. Choose the single frontier question that most changes scope, architecture, acceptance, safety, or
   validation.
4. Name the branch it controls, ask one decisive question, and provide a recommended answer with the
   reason.
5. Recompute the frontier after the answer. Record a safe assumption only when the unresolved branch
   is non-critical and does not risk building the wrong thing.

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
- Stop grilling when the decision tree has no material unresolved frontier.
