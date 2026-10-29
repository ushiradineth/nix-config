# Polish and finish

Polish follows the structural and interaction work. Preserve the established world, factual copy,
behavior and scope. If the concept is wrong, identify that problem rather than concealing a redesign
inside finishing edits.

Start from relevant existing findings and the project's component/token rules. Inspect the whole
affected path once, collecting related defects before editing. Prioritize broken behavior and
accessibility over cosmetic alignment.

- Confirm the primary action, hierarchy, labels and feedback are immediately understandable.
- Align spacing, type roles, icons, optical details and semantic colors with neighboring components.
- Check actual content: long/short values, empty and error states, loading and success, wrapping,
  relevant themes and supported sizes.
- Check focus visibility/order/restoration, keyboard actions and appropriate pointer/touch targets.
- Verify overlays escape clipping, sticky areas do not cover controls, and font/image loading does
  not disrupt the path.
- Keep motion coherent, interruptible and compatible with reduced-motion preferences.
- Remove dead styles, placeholder data, accidental diagnostics and unused assets from the scoped
  diff. Preserve non-obvious rationale and required content.

Fix the findings as a coherent batch, then confirm the changed states and run the relevant project
checks. Repeat only for a remaining defect or a material new change. Stop when the requested path is
complete; do not iterate indefinitely over subjective micro-adjustments.

For web work, use the installed `browser-workflow` within its authority. For native work, use the
actual preview/device/test workflow. Describe the inspected sizes, states and interactions; avoid
claiming browser, device, assistive-technology or performance coverage that did not run.

Return a compact account of the visible improvement and verification. The parent Jiyu workflow owns
final code review and delivery; do not duplicate that pass or commit/deploy without the user's
authorization.
