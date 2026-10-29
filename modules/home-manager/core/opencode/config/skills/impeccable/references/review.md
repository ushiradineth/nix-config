# Critique and UI audit

An explicit critique or audit is read-only unless fixes were also requested. In an implementation
task, use the relevant findings to improve the authorized work. Keep the review on the named
surface; do not turn UI audit into a whole-repository security or architecture review.

## Critique: is the experience good?

Walk the primary user task in representative states and sizes. Assess:

- **Purpose and hierarchy:** can the intended user identify the main action and relevant evidence?
  Does visual weight match product priority, or does everything compete equally?
- **Information and effort:** is the user forced to remember facts across screens, translate jargon,
  or open several places to make one decision? Group related material and disclose complexity where
  it becomes useful; do not impose an arbitrary item count on inherently complex work.
- **Affordances and feedback:** do controls look actionable and behave consistently? Are location,
  selection, progress, save state and recovery clear?
- **Identity and craft:** does the design express this product or an unexamined template? Repeated
  icon cards, fake metrics and effects can hide missing content. Familiar product controls are not
  automatically generic or wrong.
- **Use conditions:** consider a first-time user, an experienced user and a relevant accessibility
  or mobile constraint when their task differs. Report concrete friction, not invented personas.

Distinguish a structural problem from a finishing defect. A wrong task model needs shape/redesign;
alignment tweaks cannot repair it. Use `layout`, `clarify`, `distill`, `onboard` or an expression
technique for the specific cause.

## Audit: does the UI hold up?

Use current source, computed styles, the rendered interface and existing accessibility/performance
tools as appropriate. Report which evidence exists; a source inspection is not a screen-reader test,
physical touch test or measured render profile.

- **Accessibility:** semantics, names/labels, heading/landmark structure, keyboard access, visible
  focus, focus restoration, errors, contrast, zoom and motion preferences. Verify real tab order and
  controls instead of treating an ARIA attribute count as accessibility.
- **Performance:** image/font delivery, layout shift, interaction delay, rendering work and motion
  cost. Establish an observed bottleneck before suggesting lazy loading or memoization everywhere.
- **Theming:** semantic tokens, relevant light/dark states, status contrast and theme transitions.
  An unused dark theme is not a requirement to add one.
- **Adaptation:** wrapping, long values, viewport/container changes, input modes, focus order,
  overlays, sticky content and touch interaction. A narrow screenshot does not exercise a drag.
- **Implementation integrity:** source and render agree; controls work; content is real; the
  component vocabulary and state behavior are coherent across the scoped path.

Use the platform reference on native work. Do not apply browser-only tests to a native preview.

## Findings and next action

Prioritize blocking task failure, then major confusion or accessibility failures, then minor
friction and cosmetic inconsistencies. For each material finding, name the target/state, observed
evidence, user impact and smallest useful correction. Distinguish verified defects, hypotheses and
preferences.

A compact severity scale can help: P0 prevents the task, P1 causes major difficulty, P2 is friction
with a workaround, P3 is cosmetic. Avoid a numerical quality score unless useful or requested; never
imply an untested dimension passed. Recommend the relevant technique and scope. A review request
ends with findings, rather than silently fixing them or asking the user to approve the review.
