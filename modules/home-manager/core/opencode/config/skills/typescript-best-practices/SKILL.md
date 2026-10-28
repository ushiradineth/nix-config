---
name: typescript-best-practices
description:
  "Use when reading or editing TypeScript, TSX, MTS or CTS: model domain states, validate external
  data and preserve useful type inference."
license: MIT
---

# TypeScript best practices

Follow the repository's actual compiler settings, runtime and test framework.

- Model variants with discriminated unions. Avoid bags of optional fields that admit impossible
  combinations. Strengthen a type only where its operations need the stronger invariant.
- Accept external data as `unknown`; parse at the boundary with the existing schema library and
  infer the type. Trust the parsed domain model internally.
- Prefer inference, `satisfies`, `Pick`, `Omit`, `Parameters`, `ReturnType` and `Awaited` over
  duplicate interfaces or casts. Preserve literals with `as const` where useful.
- Avoid `any`, non-null assertions and forced casts that conceal an unchecked assumption. A
  necessary library interop cast belongs at the validated boundary with a clear invariant.
- Use truthful type guards and exhaustive variant handling. Brand primitives only where confusing
  them is a real domain risk; create brands through validated constructors.
- Keep the canonical owner for state and contracts. Prefer explicit data flow over broad registries,
  boolean mode combinations and wrappers that add no meaning.
- Use object parameters where positional arguments are easy to confuse, not as a universal rewrite.
- Test observable behavior through native TypeScript tests and real dependencies where practical.
  Mock only the unavailable boundary, not the behavior under test.
- Use the project's structured diagnostics. Remove temporary debug logging; do not forbid useful CLI
  output or an established logger just because it ultimately writes to a console.

Run the component's type check and affected behavioral tests. Do not weaken compiler settings to
make the change pass.
