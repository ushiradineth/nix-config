---
name: fallow
description:
  Use for JavaScript or TypeScript codebase intelligence, changed-code readiness, dead-code or
  dependency analysis, duplication, complexity, architecture, or advisory security candidates.
---

# Fallow

## Core rule

Use Fallow as local deterministic evidence, not as proof or a replacement for tests, type checks,
lint, or source review.

## Boundaries

- Use only for JavaScript or TypeScript repositories.
- Do not use it for runtime debugging, compiler diagnostics, formatting, dependency CVEs, or
  verified vulnerability claims.
- Never run `watch`, `agent install`, hook installers, MCP setup, telemetry enablement, or remote
  configuration. Do not pass `--allow-remote-extends`.
- Keep telemetry and update checks disabled for agent runs with
  `FALLOW_TELEMETRY_DISABLED=1 FALLOW_UPDATE_CHECK=off`.
- Treat `fallow security` output as candidates. Verify source, data flow, and reachability through
  `security-audit` guidance before calling anything a vulnerability or editing code.

## Workflow

1. Select the narrowest command that answers the request.
2. Run it with `--format json --quiet` and the telemetry/update kill switches.
3. Preserve the exit status. Codes 0 and 1 are completed analyses; any other code is a tool or
   configuration failure.
4. Verify each candidate against source evidence. Do not suppress or fix unexplained findings.
5. Run repository-native checks after any accepted fix.

Changed-code readiness:

```sh
rc=0
FALLOW_TELEMETRY_DISABLED=1 FALLOW_UPDATE_CHECK=off \
  fallow audit --base <ref> --format json --quiet || rc=$?
test "$rc" -eq 0 -o "$rc" -eq 1
```

Common focused commands:

```sh
FALLOW_TELEMETRY_DISABLED=1 FALLOW_UPDATE_CHECK=off fallow dead-code --format json --quiet
FALLOW_TELEMETRY_DISABLED=1 FALLOW_UPDATE_CHECK=off fallow dupes --format json --quiet
FALLOW_TELEMETRY_DISABLED=1 FALLOW_UPDATE_CHECK=off fallow health --hotspots --targets --format json --quiet
FALLOW_TELEMETRY_DISABLED=1 FALLOW_UPDATE_CHECK=off fallow security --format json --quiet
```

For supported fixes, run `fallow fix --dry-run --format json --quiet` first. Apply only reviewed
changes with `fix --yes`, then rerun the original analysis and repository checks.

## Completion

Report the command, base or scope, exit code, introduced versus inherited findings, verification
status, and remaining uncertainty. A clean Fallow result supplements rather than replaces the
repository's required validation gates.
