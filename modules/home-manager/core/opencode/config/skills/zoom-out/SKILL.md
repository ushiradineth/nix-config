---
name: zoom-out
description:
  Use when the code area is unfamiliar, the user asks for a map, or implementation needs broader
  module, caller, data-flow, or ownership context before editing.
---

# Zoom out

## Core rule

Go up one abstraction level before editing unfamiliar code.

## Workflow

1. Identify the requested area and likely entry points.
2. Map nearby modules, callers, and owned responsibilities.
3. Summarize data flow, control flow, and boundaries.
4. Name the files worth reading next.
5. Point out risks, hidden coupling, or missing tests.

## Output

```md
Map: <area> Key modules: <files and responsibilities> Callers: <who invokes this> Flow:
<data or control path> Risks: <coupling, missing tests, unclear ownership> Read next:
<short ordered list>
```

## Boundary

This is a context skill. Do not turn it into implementation unless the active lane already has edit
authority and the task remains in scope.
