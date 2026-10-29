---
name: impeccable
description:
  Design, brainstorm, build, critique or refine user interfaces when visual or interaction design is
  part of the requested outcome. Covers screens, components, UX copy, accessibility, responsive
  layout and UI motion. Does not route backend work, architecture design or frontend logic changes
  that leave the interface experience unchanged.
license: Apache-2.0
---

# Impeccable for OpenCode

Use this as Jiyu's UI specialist in the current session. Keep the user's goal, project constraints
and engineering checks; select only the design work that serves the requested surface. File type
alone is not a trigger. On a mixed task, apply this skill to the UI portion and let Jiyu own the
integration. Backend audits, security hardening and database optimization use their normal routes.

## Start with the surface

Identify the target and whether the user wants ideas, a review, a refinement or implementation. Read
the relevant existing product/brand guidance, design tokens, components and rendered states.
PRODUCT.md, DESIGN.md and older `.impeccable.md` are useful when present; their absence does not
make an existing interface a blank slate. Read [context](references/context.md) for missing product
intent or an explicit `init`, `document` or `extract` request.

Honor the user's pinned visual direction and the project's design system. Load `kumo-design` when
the project actually uses Kumo. Prefer this entrypoint over stacking overlapping generic frontend
design workflows. A request for a small fix is not permission to replace the visual identity.

Choose the mode for this surface, not the entire product:

- **Operate:** dashboards, editors, settings and tools. Optimize task completion, familiar
  affordances, density and consistent states. Restraint can be the strongest design decision.
- **Read:** documentation and articles. Optimize comprehension, reading rhythm and navigation.
- **Persuade:** landing pages, campaigns and pricing. Give the page a product-specific point of
  view, real evidence and a clear action.
- **Experience:** portfolios, galleries and showcases. Let the work itself lead.

An app's marketing page and its settings panel need different treatment. Native interfaces retain
platform navigation, controls, scaling and input conventions: load [iOS](references/ios.md) or
[Android](references/android.md) only for that platform; use the project's own guidance for others.

## Route by the requested result

| Request or `/impeccable` argument                                  | Read                                                     | Result and stopping point                                                                    |
| ------------------------------------------------------------------ | -------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| Brainstorm UI, `shape`, plan a screen                              | [New work](references/new-work.md)                       | Distinct concepts or an actionable brief; no code unless requested.                          |
| Build a screen, redesign, `craft`                                  | [New work](references/new-work.md)                       | Implement the chosen or best-supported direction and verify it. `craft` is an alias.         |
| `init`, `document`, `extract`                                      | [Context](references/context.md)                         | Product context, an observed design-system record, or consolidated UI patterns.              |
| `critique`, `audit`                                                | [Review](references/review.md)                           | Evidence-backed design or technical UI findings; read-only unless fixes were also requested. |
| `layout`, `typeset`, `clarify`, `distill`                          | [Refine](references/refine.md)                           | Improve structure, typography, interface language or simplicity within scope.                |
| `harden`, `adapt`, `onboard`, `optimize`                           | [Resilience](references/resilience.md)                   | Robust states, appropriate adaptation, faster first value or measured UI performance.        |
| `colorize`, `bolder`, `quieter`, `animate`, `delight`, `overdrive` | [Expression](references/expression.md)                   | A purposeful change in visual or interaction character.                                      |
| `polish`                                                           | [Finish](references/finish.md)                           | Final consistency and state checks after structural work.                                    |
| `generate`, compare variants                                       | [New work](references/new-work.md#variants-and-previews) | Distinct alternatives on the named target; implement a selection when requested.             |
| `live`, `hooks`, `pin`, `unpin`, `doctor`, or usage help           | [Utilities](references/utilities.md)                     | Explicit tooling or maintenance scope; no automatic services or installs.                    |

For a normal UI request, choose a route and do the work. Do not make the user invoke skills or
approve a restatement. When several techniques fit, start with the one that removes the largest
obstacle and load another reference only when needed. For bare `/impeccable` with no arguments,
offer two or three context-specific next moves and stop; a menu is not permission to run them.
Inside this command, `teach` aliases `init`; top-level `/teach` still explains code.

The useful sequence is context → shape/build → critique/audit → targeted fixes → polish. It is a
dependency order, not a checklist for every task. Do not turn a spacing fix into an interview,
design-system extraction, two audits and a redesign. Use critique and audit together when both
usability judgment and technical UI evidence matter; otherwise choose the relevant one.

## Craft and proof

Build from real content and user tasks. Repeated card grids, gradient text, icon tiles, decorative
labels, gratuitous glass, effects and invented metrics are poor substitutes for a composition. Use
them only when they serve the brief or established system; do not impose a universal aesthetic ban
over explicit user choices. Familiar controls and system fonts often serve Operate surfaces well.

Verify the rendered result at the sizes and states the change affects. Use `browser-workflow` for
web inspection and interaction, or the project's native preview/test path. Batch observations and
fixes; repeat for a material change or unresolved defect, not endless cosmetic self-review. Check
keyboard/focus, real content extremes, contrast and reduced-motion behavior as applicable. A
screenshot proves appearance in one state, not that a control works. If rendering is unavailable,
use current source and trustworthy visual fixtures, and report the remaining visual check honestly.

Implementation includes the project's functional and integration checks. At the completed code
boundary, use Jiyu's [attack-the-diff](../jiyu-mode/playbooks/attack-the-diff.md) once; reuse the
parent task's pass rather than adding a second review pipeline. Read-only reviews and brainstorming
do not run code-delivery gates. Report the visible result, the relevant evidence and any real gap.
