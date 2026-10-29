# Real use, adaptation and UI performance

## Harden

Exercise the states that stress this interface: missing/long content, empty results, loading,
partial failure, retries, offline behavior, permissions, invalid inputs and repeated actions.

Preserve input and task progress after an error. Prevent accidental duplicate actions without
turning every transient state into a blocking screen. Give the user truthful progress and a feasible
recovery. Keep client validation aligned with the real API; do not manufacture successful behavior.

Check overflow and wrapping, localized text and number/date formats, zoom, keyboard focus,
disabled/loading semantics and announcements where appropriate. Custom drag surfaces need pointer
cancel/lost-capture behavior and intentional touch/scroll handling. Exercise the interaction;
viewport emulation alone cannot prove it.

This is interface resilience, not an unrequested backend security audit or a new validation layer
around already-trusted internal values.

## Adapt

Adapt the task to the new context rather than shrinking the desktop layout. Preserve essential
content and actions; decide what collapses, changes navigation, becomes scrollable or gains
progressive disclosure. Compact product UI may stay dense if it remains operable.

Use content/container constraints to choose breakpoints. Check narrow, intermediate and wide
layouts, orientation/zoom, safe areas, touch and keyboard. Keep focused items and essential actions
reachable when keyboards or overlays appear. Avoid hidden duplicate controls that disagree on state
or accessible names. Use native platform guidance for native work.

Print and email are distinct contexts with different interaction and rendering constraints; do not
assume the web screen can be copied unchanged. Test the actual target the user requested.

## Onboard

Identify the first action that proves value and remove obstacles to it. Prefer a useful first-run
state or contextual help to a mandatory tour of every feature. Allow experienced users to skip
orientation and find it again when useful.

An empty state explains what belongs there and offers the next useful action when it is not already
obvious. Sample content must be clearly labeled and cannot pretend to be real account data. Do not
front-load optional permissions, profile details or settings before they earn their place.

Verify first use, returning use, skip/dismiss, reload and interrupted completion. Do not re-show
onboarding after every visit or make help obstruct the task it explains.

## Optimize

Measure the actual UI bottleneck: loading, interaction latency, rendering, layout shift, animation,
font/image delivery or an oversized bundle. Use comparable before/after conditions and the project's
existing tools. Source patterns alone are hypotheses about performance.

Match the fix to the measured cause. Prioritize critical assets instead of lazy-loading the image
needed for the first viewport. Bound or virtualize genuinely expensive lists; do not add memoization
without evidence that the work matters. Reserve geometry for images/content and tune font fallback
to reduce reflow. Keep costly effects targeted and interruptible.

Verify the same task after the change, including relevant low-end/mobile conditions and behavior
regressions. Use `benchmark-checklist` for meaningful measured claims. Do not claim a Web Vitals or
frame-rate improvement from a successful build or static screenshot. Backend performance follows
Jiyu's normal performance route rather than this UI-specific reference.
