# ❄️ Nix Configuration

This repository contains my nix configuration for all my machines.

## Reference

This repository drew significant inspiration from the outstanding work done by
[Ryan Yin](https://github.com/ryan4yin). The following repositories were referenced:

- [nix-config](https://github.com/ryan4yin/nix-config)
- [nix-darwin-kickstarter](https://github.com/ryan4yin/nix-darwin-kickstarter)

## Configuration Structure

```bash
.
├── hosts/                            # per-host configurations
├── lib/                              # helper functions)
├── parts/                            # non-host flake modules
│   └── development.nix               # formatter/checks/devShell
├── outputs/                          # host output modules
│   ├── linux/                        # nixosConfigurations per host
│   ├── darwin/                       # darwinConfigurations per host
│   └── colmena/                      # colmena node outputs per host
├── overlays/                         # reusable nixpkgs overlays
├── flakes/                           # standalone dev env templates
├── modules/                          # shared module library
│   ├── home-manager/                 # reusable home-manager modules
│   │   ├── core/
│   │   ├── darwin/
│   │   └── linux/
│   └── nix-modules/                  # reusable NixOS / nix-darwin modules
│       ├── core/
│       ├── darwin/
│       └── linux/
├── vars/                             # shared variables
├── flake.nix                         # main entry point
├── flake.lock                        # pinned inputs
├── README.md                         # repo overview
├── docs/                             # documentation
│   ├── NIX_DARWIN_INSTALLATION.md    # macOS install guide
│   ├── NIXOS_INSTALLATION.md         # nixOS install notes
│   └── RASPBERRY_PI_INSTALLATION.md  # Raspberry Pi 5 setup notes
├── Justfile                          # helper commands
└── result -> /nix/store/...          # symlink to last build (if present)
```

## Documentation

- **Installation Guides**
  - [macOS (nix-darwin)](./docs/NIX_DARWIN_INSTALLATION.md)
  - [NixOS General](./docs/NIXOS_INSTALLATION.md)
  - [Raspberry Pi 5 Setup](./docs/RASPBERRY_PI_INSTALLATION.md)
- **Host Documentation**
  - ./hosts/(host)/README.md

## Colmena & nixos-anywhere

- `just init <hostname>` wraps nixos-anywhere to bootstrap a remote machine. Pick the hostname (e.g.
  `just init shupi`) and it will run the appropriate flake output against the target over SSH.
- `just deploy <hostname> [mode]` applies changes via Colmena. The mode defaults to `switch` and can
  be `switch`, `boot`, or `dry-activate`. Tags default to each hostname, so `shupi` affects only
  `shupi`; group tags can be added in the per-host Colmena definition if needed.

## Local Dev Environments

- Copy a template from `flakes/` into the target repo and adjust it there.
- Global git ignore is configured for local dev-env artifacts (`.envrc`, `.direnv/`, `flake.nix`,
  `flake.lock`) to reduce accidental commits when bootstrapping non-Nix repos.

## Checks

- `just fmt` runs treefmt.
- `just check` runs `nix flake check --all-systems` (includes pre-commit hooks: alejandra, prettier,
  deadnix, statix, typos).
- Global typo ignores live in `modules/home-manager/core/typos.toml`. Project-specific ignores live
  in a `.typos.toml` at that project's root. The shell command and Neovim LSP combine both files,
  with global settings taking precedence when the same key exists in both.

## Local application security scans

Home Manager installs `semgrep-local` and an immutable baseline link at
`~/.config/semgrep/baseline`. The command scans source under OS network and source-write denial,
uses only local rules, and refuses to run if confinement is unavailable. It does not execute
application code, install hooks, or create tooling files in the scanned repository.

```sh
semgrep-local --root /absolute/path/to/application
semgrep-local --root /absolute/path/to/application --files src/api.ts src/store.ts
semgrep-local --root /absolute/path/to/application --profile project-a
```

The baseline has eleven detector families for JS/TS, Python, Go, and Rust: browser injection,
selected request-to-shell flows, unsafe TLS options, unsafe PyYAML loaders, and a formatted-SQLx
query heuristic. Exact rule IDs, confidence levels and blind spots are in
[`security/semgrep/manifest.json`](security/semgrep/manifest.json). Coverage is bounded and
intraprocedural; a clean result is not a whole-application security assessment or a substitute for
native checks. Internal no-finding controls force AST parsing even when security-rule prefilters
select no source. Generated directories are excluded and listed in each report.

JSON goes to stdout. Exit `0` means a completed scan without candidates, `1` means candidates
requiring source review, and `2` means validation/engine failure or incomplete scope. Parser errors,
timeouts, skipped requested files/rules, and empty scopes cannot report clean. `--output` accepts
only a new report file outside source and configuration directories, creates it with mode `0600`,
and never overwrites it. It does not create parent directories. There are no passthrough engine
flags.

Private profiles live at `${XDG_CONFIG_HOME:-$HOME/.config}/semgrep/profiles/<id>/profile.json`.
Keep them out of application repositories and Nix inputs. The profile directory and any rule
subdirectories must be user-owned with mode `0700`; profile, YAML and fixture files must have mode
`0600`. A profile adds rules without replacing the baseline, binds to one canonical project root,
and declares any additional exclusions. For example, privately replace this synthetic root:

```json
{
  "version": 1,
  "root": "/absolute/path/to/application",
  "rule_files": ["rules/private-check.yml"],
  "exclude": ["generated/*"]
}
```

`rule_files` and `exclude` can be empty. Custom YAML must use the supported local schema, unique
rule IDs, and paired same-basename fixtures such as `private-check.yml`/`private-check.ts`. Every
selected custom rule needs `ruleid:` and `ok:` annotations; the runner validates their static tests
before scanning. It freezes those inputs in private temporary storage and deletes the storage after
the scan. Unknown fields, remote configurations, executable rule extensions, missing fixtures,
incorrect permissions and mismatched roots fail closed. The profile shape is documented in
[`profile.schema.json`](security/semgrep/profile.schema.json); runtime checks also enforce canonical
paths, ownership and local rule safety.

`nix build --no-link .#checks.aarch64-darwin.semgrep-local` runs the baseline fixture suites and
runner unit regressions. Actual OS confinement/CLI tests run separately through
`SEMGREP_LOCAL_BINARY=<built-package>/bin/semgrep-local python3 tests/semgrep-local-test.py --runtime`
in a Python environment with PyYAML. macOS uses `/usr/bin/sandbox-exec`; Linux uses packaged
Bubblewrap and may refuse to run when user namespaces are disabled. Native Linux isolation is not
established by mocked unit checks or Nix evaluation.

Build-only validation does not activate Home Manager changes. Use the built package path until an
explicitly approved apply, then restart OpenCode to load the updated managed skill guidance.

## Shared Host Registry

- `vars/default.nix` defines `hostAddresses`: a shared map of hostnames to IPs.
- `modules/nix-modules/core/ssh.nix` consumes this list to generate system SSH aliases.
- Update `hostAddresses` whenever a new host is added, and both nix-darwin and NixOS configurations
  pick it up automatically.
