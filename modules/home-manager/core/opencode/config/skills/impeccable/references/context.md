# Product context and the design system

Reuse settled answers. Read the user's brief, repository guidance, brand material, existing
components/tokens and relevant product notes before asking for missing intent. Source shows current
behavior; it cannot prove who the intended audience is or which brand commitments are deliberate.
Distinguish observed facts from assumptions. Ask only for a gap that materially changes the result.

A narrow refinement can proceed from the incumbent system. A new product or replacement visual
identity needs enough direction to avoid inventing its audience, promise or factual claims. Work on
independent investigation while an essential answer is pending.

## Init

`/impeccable init` captures durable product truth. Establish:

- who uses it, in what situation, and the job they need to finish;
- the primary outcome, actual capabilities and product evidence;
- binding platform, accessibility, performance, content and brand constraints.

Update an existing PRODUCT.md or the project's established product document in place. Keep facts
separate from open questions; never replace a current brief with guessed positioning. Avoid visual
recipes here: typography and colors belong to the visual system. Do not configure a dev server,
install an overlay or create parallel journals as a side effect.

If init was a prerequisite within an authorized build, resume that work using the answers already
collected. An explicit context-only request ends after the context deliverable.

## Document

`/impeccable document` records the existing visual system rather than proposing a redesign. Trace
canonical tokens, theme definitions, type assets, layout primitives and representative components.
Inspect more than one state/theme before calling an isolated value a rule.

Capture the useful subset in DESIGN.md or its existing equivalent:

- the design's purpose and visual character, with observed examples;
- semantic colors and states, light/dark relationships and source locations;
- type roles, weights, measure and hierarchy;
- spacing, containers, density and responsive structure;
- components, icons, elevation, shape and interaction/motion conventions;
- known exceptions and unresolved inconsistencies.

Link to source for exact token values instead of copying a second dictionary that immediately
drifts. Preserve an existing document's schema and consumers. Label proposed rules separately from
observed ones. A document request does not authorize normalizing the code it describes.

## Extract

`/impeccable extract` turns genuinely repeated UI patterns into shared tokens or components.

1. Find the canonical design-system owner and compare actual repeated instances, including states
   and callers. Several similar-looking boxes need not share behavior or ownership.
2. Extract a semantic role with a small API when repeated use justifies it. Do not create a design
   framework for a single screen or put arbitrary values behind meaningless token names.
3. Migrate the affected callers together. Preserve accessible semantics and useful differences;
   delete the superseded paths instead of leaving two sources of truth.
4. Verify representative callers and themes, then update the existing design record if it changed.

For ordinary UI tasks, read relevant context directly. Do not require PRODUCT.md, DESIGN.md,
generated sidecars or an extraction pass before making a local fix.
