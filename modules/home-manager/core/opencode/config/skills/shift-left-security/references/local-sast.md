# Local SAST and staged enforcement

## Static analysis

1. Prefer `semgrep-local` with the managed central baseline and an explicitly selected private
   profile when applicable. Repository-owned reviewed rules can supplement native checks, but never
   add personal rules/configuration/hooks to work repositories. Do not use registry aliases, URLs,
   `--config auto`, or any configuration that downloads rules.
2. Run the smallest explicit source scope:

   ```sh
   semgrep-local --root /absolute/path/to/project --files src/api.ts src/store.ts
   semgrep-local --root /absolute/path/to/project --profile project-a --files src/api.ts
   ```

3. The helper uses pinned local rules, OSS analysis, disabled telemetry/version checks and enforced
   network/source-write denial. It never executes source, installs hooks or writes into the project.
   Profiles under `$XDG_CONFIG_HOME/semgrep/profiles/` (default `~/.config/semgrep/profiles/`) are
   private, additive and bound to a canonical project root. Their custom fixtures must pass before
   analysis. Do not create real private profiles without user approval.
4. Read JSON status, exact scanned paths, exclusions, rule confidence and blind spots. Exit `0` is a
   completed scan without candidates; `1` is completed candidate analysis, not tool failure or proof
   of a vulnerability; `2` is validation/engine failure or incomplete scope. Empty/skipped requested
   scopes, parser errors, failed fixtures and missing confinement cannot count as a clean pass. If
   the command is absent or refuses confinement, report the blocker and request tooling activation;
   never substitute a bare scanner or silently install into the target repository.
5. Keep output on stdout or request a new private `--output` file outside the project and config
   roots; the helper never overwrites reports. Do not put work data into public rules, examples or
   Nix inputs. Re-run applicable local SAST after relevant edits and before readiness. Record the
   command, engine version, scan scope and findings; verify candidates against source before action.
6. Native rule tests must prove unsafe matches and safe non-matches before readiness. Do not execute
   fixtures, fetch `--validate` rule lints, or add unexplained suppressions. A clean baseline is
   bounded JS/TS/Python/Go/Rust evidence, not a whole-service assessment or a replacement for native
   tests/type checks. macOS confinement is runtime-tested separately; Linux namespace availability
   must be verified locally rather than inferred from Nix evaluation.

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
