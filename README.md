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
- `just deploy <hostname>` applies changes via Colmena. Tags default to each hostname, so `shupi`
  affects only `shupi`; group tags can be added in the per-host Colmena definition if needed.

## Local Dev Environments

- Copy a template from `flakes/` into the target repo and adjust it there.
- Global git ignore is configured for local dev-env artifacts (`.envrc`, `.direnv/`, `flake.nix`,
  `flake.lock`) to reduce accidental commits when bootstrapping non-Nix repos.

## Checks

- `just fmt` runs treefmt.
- `just check` runs `nix flake check --all-systems` (includes pre-commit hooks: alejandra, prettier,
  deadnix, statix).

## Shared Host Registry

- `vars/default.nix` defines `hostAddresses`: a shared map of hostnames to IPs.
- `modules/nix-modules/core/ssh.nix` consumes this list to write `/etc/hosts` and generate SSH
  aliases everywhere.
- Update `hostAddresses` whenever a new host is added, and both nix-darwin and NixOS configurations
  pick it up automatically.
