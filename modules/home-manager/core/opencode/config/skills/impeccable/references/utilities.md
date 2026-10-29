# Explicit helpers and tool boundaries

## Choosing a command

A bare `/impeccable` shows a small menu tailored to the current UI and ends. A question about how to
use the skills is advice, not an instruction to build or run setup. Normal UI requests already route
automatically; users do not need to memorize a sequence.

`/impeccable init` captures product context. `/impeccable document` records the current visual
system. `/impeccable shape` plans without code. The top-level `/init` still creates repository
AGENTS.md, and `/teach` still explains code; those engineering commands are unchanged. Inside
`/impeccable`, `teach` is accepted as the upstream alias for `init`.

## Live and generate

Use [variants and previews](new-work.md#variants-and-previews) for alternatives through the existing
tools. This adaptation does not install upstream's live-picker overlay, inject its browser bundle,
start a listener, or run a polling loop. Do not claim that an ordinary browser preview is that tool.

When specifically asked for the upstream picker, explain its absence and determine the necessary
installation scope before changing the harness. Existing user-owned dev servers stay user-owned.
Inspect or use a running preview only through the project's supported browser/native procedure.

## Hooks, pin and unpin

The upstream detector hooks and shortcut-writing scripts are not bundled. Do not run `npx`, download
an engine, modify runtime hooks or create commands as a side effect of UI work. A request for those
features is an explicit harness/tooling task; inspect the installed runtime and managed source
before proposing or implementing it. Keep any future detector restricted to design tasks rather than
adding scans after ordinary development edits.

All design techniques are available under `/impeccable <technique>`. This avoids collisions with
engineering commands and does not need automatic per-project shortcut generation.

## Doctor

For an explicit `/impeccable doctor`, inspect the existing product/design context against current
source, assets and task constraints. Report stale observations and broken references. Distinguish
mechanical drift from product truth that needs the user's answer. Repair when requested, within the
named files; do not treat document age as permission to redesign the interface or regenerate all
guidance. Ordinary UI work does not run this maintenance pass.
