# Local SAST and staged enforcement

## Static analysis

1. Prefer repository-owned, reviewed rules. Do not use registry aliases, URLs, `--config auto`, or
   any configuration that downloads rules.
2. For Semgrep, disable metrics and version checks in the command itself:

   ```sh
   SEMGREP_SEND_METRICS=off SEMGREP_ENABLE_VERSION_CHECK=0 \
     semgrep scan --config <local-rule-path> --strict --error --metrics=off \
     --disable-version-check --disable-nosem <targets>
   ```

3. Run rule tests before allowing a rule to block work. Fixtures must prove unsafe matches and safe
   non-matches. Refine false positives rather than adding unexplained suppressions.
4. Run applicable local SAST after relevant edits and before readiness. Record exact findings and
   scanned scope.

## Staged-file policy

- A pre-commit hook may block only locally tested high-confidence rules and must receive staged
  filenames rather than silently widening to the repository.
- Keep broader scans and Fallow advisory. A local hook is an early feedback layer, not release or CI
  enforcement.
- Hook installation is user-owned. Never run `pre-commit install` automatically, and document the
  commit-time `PATH` requirement for system-language hooks.

## Fallow candidates

Run Fallow with telemetry and update checks disabled, machine-readable output, and preserved exit
status:

```sh
rc=0
FALLOW_TELEMETRY_DISABLED=1 FALLOW_UPDATE_CHECK=off \
  fallow audit --base <ref> --format json --quiet || rc=$?
test "$rc" -eq 0 -o "$rc" -eq 1
```

Codes 0 and 1 are completed analyses. Treat `fallow security` and other broad findings as candidate
evidence, not proof. Verify a candidate through `security-audit` guidance before labeling a defect,
suppressing it, or editing code.
