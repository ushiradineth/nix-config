---
name: architecture-deepening
description:
  Use when reviewing architecture, planning refactors, reducing coupling, improving testability, or
  deciding whether modules should become deeper behind simpler interfaces.
---

# Architecture deepening

## Core rule

Prefer deep modules: simple interface, useful behavior behind it, clear test surface.

## Vocabulary

- Module: function, class, package, slice, or tool with an interface and implementation.
- Interface: everything a caller must know to use the module, including types, invariants, errors,
  ordering, and configuration.
- Implementation: code hidden behind the interface.
- Depth: leverage from a small interface over meaningful behavior.
- Seam: place where behavior can vary without editing every caller.
- Adapter: concrete implementation at a seam.
- Locality: change and bugs concentrate in one place.

## Review questions

- Does understanding one concept require bouncing through many shallow files?
- Does deleting a module remove complexity, or just spread it across callers?
- Is the interface nearly as complex as the implementation?
- Are tests forced to mock internals because the real interface is not testable?
- Would two adapters make this seam real, or is it hypothetical?

## Output

Return candidates with files, problem, smallest safe improvement, test impact, risk, and confidence.
Do not implement broad refactors unless an accepted plan authorizes them.
