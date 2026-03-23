---
name: brainstorming
description:
  Use when a request is feature design heavy, ambiguous, or likely to change architecture. Turn
  ideas into an approved design before implementation handoff.
---

# Brainstorming

## Trigger conditions

Use this skill when at least one is true:

- the user asks for a new feature with unclear constraints
- the request spans multiple subsystems or files with architectural impact
- the user asks for ideas, approaches, or design options before coding

Do not use for small, already-clear single-file fixes.

## Core rule

Do not implement code changes until a design direction is presented and accepted.

## Workflow

1. Ground in current context first.
   - Run Veil retrieval first to map relevant modules and constraints.
2. Clarify one thing at a time.
   - Ask focused questions only where ambiguity changes implementation.
3. Propose options.
   - Present 2-3 viable approaches with tradeoffs.
   - Lead with a recommended option and why.
4. Present design for approval.
   - Cover architecture, key components, data flow, failure handling, and verification strategy.
5. Transition cleanly.
   - For multi-step work, hand off to planner workflow and plan file creation.
   - For simple approved work, continue in direct execution mode.
   - For ideation deliverables, route execution through the `ideate` subagent.
   - For writing deliverables, route execution through the `writer` subagent.

## Output contract

Return these sections:

1. `Context`: relevant files, constraints, and assumptions.
2. `Options`: 2-3 approaches with pros and risks.
3. `Recommendation`: preferred approach and reasoning.
4. `Proposed design`: implementation-ready outline.
5. `Approval gate`: explicit prompt for user approval before implementation.

## Anti-patterns

- jumping straight into code before design acceptance
- presenting only one approach when tradeoffs are material
- broad speculative redesign outside the requested scope
