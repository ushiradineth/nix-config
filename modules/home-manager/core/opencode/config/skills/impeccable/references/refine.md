# Structure, type, language and simplicity

Preserve the established identity and everything outside the named target. Find the cause before
moving boxes or changing values. Use the actual copy, data ranges and rendered states.

## Layout

Establish the primary reading/task path, meaningful groups, leading element and intended density.
Use proximity and deliberate tight/generous spacing before adding more containers. Equivalent
content should look related; distinct jobs should not be forced into identical cards.

Choose a structural model that expresses those relationships. Reuse spacing and container roles;
prefer a parent `gap` where it owns sibling rhythm. Use the squint test to inspect hierarchy rather
than treating every spacing value as an isolated defect.

Responsive layout changes priorities: reflow, collapse, reorder or disclose as appropriate. Keep
visual, DOM and keyboard order aligned. Test long content, intermediate widths, zoom, sticky areas
and overlays. A clipped menu often needs the correct overlay layer or portal, not another z-index.

## Typeset

Identify the existing family, real font files/weights and semantic roles before replacing a face.
Clarify heading, body, label, metadata and data hierarchy with a coherent role scale. Operate UI
often benefits from one well-tuned family and stable sizes; expressive display type belongs where
the surface and brand earn it.

Tune measure, line height, wrapping and paragraph rhythm to actual language and width. Roughly 45–75
characters can be useful for prose, not a width limit for data tables. Check fallback fonts, missing
weights, font-loading reflow, zoom and localization. Use tabular numerals when alignment helps
comparison; do not use monospace as a costume for every technical product.

Preserve pinned fonts and brand choices. A type refinement changes their use; replacing the identity
is a redesign decision. Load only the weights/assets actually needed.

## Clarify

Make interface language answer what happened, why it matters and what the user can do next.

- Buttons name the action and, where useful, its object. Prefer a specific verb to ambiguous “OK”.
- Labels remain present; placeholders are examples rather than the only accessible instruction.
- Errors identify the problem, preserve the user's input and give a feasible recovery. Do not expose
  internal diagnostics or imply a retry can fix an authorization failure.
- Distinguish first-use emptiness, no matching results, unavailable data and permission limits.
  Explain only what the user needs to act; do not add paragraphs to every empty panel.
- Loading/success feedback is truthful. Never imply a save completed before it did.

Keep terminology, factual claims and the product's voice. Avoid blame, cleverness in stressful
moments, unnecessary jargon and redundant help. Test strings in their real space, including
translation expansion and accessible names. Authored UI text is not a new marketing promise.

## Distill

Remove redundant information, decorative noise, repeated controls and decisions that do not serve
the primary task. Prefer a clear hierarchy to hiding everything in menus. Retain necessary status,
labels, accessibility cues, recovery paths and expert functionality.

Simplify interactions and source together when it removes the actual cause. Do not consolidate
distinct concepts solely because they share markup. Verify the user can still complete the same
required tasks and recognize the same state with less work. Report consequential removals.

Once the structural or language problem is fixed, use [finish](finish.md) for the relevant final
checks; do not restart a broad design review for an isolated refinement.
