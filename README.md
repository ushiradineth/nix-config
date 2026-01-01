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
├── flakes/                           # language/tool flakes
├── hosts/                            # per-host configurations
├── lib/                              # helper functions)
├── modules/                          # shared module library
│   ├── README.md
│   ├── home-manager/                 # reusable home-manager modules
│   │   ├── core/
│   │   ├── darwin/
│   │   └── linux/
│   └── nix-modules/                  # reusable NixOS / nix-darwin modules
│       ├── core/
│       ├── darwin/
│       └── linux/
├── outputs/                          # flake outputs grouped by system/architecture
│   ├── aarch64-linux/
│   │   ├── src/                      # aarch64-linux host entries
│   │   └── default.nix
│   ├── aarch64-darwin/
│   │   ├── src/                      # aarch64-darwin host entries
│   │   └── default.nix
│   ├── x86_64-linux/
│   │   ├── src/                      # x86_64-linux host entries
│   │   └── default.nix
│   └── default.nix                   # merges architecture-specific outputs
├── vars/                             # shared variables
├── flake.nix                         # main entry point
├── flake.lock                        # pinned inputs
├── README.md                         # repo overview
├── docs/                             # documentation
│   ├── NIX_DARWIN_INSTALLATION.md    # macOS install guide
│   ├── NIXOS_INSTALLATION.md         # nixOS install notes
│   ├── RASPBERRY_PI_INSTALLATION.md  # Raspberry Pi 5 setup notes
│   └── README.md
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

- `just init <hostname>` wraps nixos-anywhere to bootstrap a remote machine. Pick the hostname (e.g. `just init shupi`) and it will run the appropriate flake output against the target over SSH.
- `just deploy <hostname>` applies changes via Colmena. Tags default to each hostname, so `shupi` affects only `shupi`; group tags can be added in the per-host Colmena definition if needed.

## Shared Host Registry

- `vars/default.nix` defines `hostAddresses`: a shared map of hostnames to IPs.
- `modules/nix-modules/core/ssh.nix` consumes this list to write `/etc/hosts` and generate SSH aliases everywhere.
- Update `hostAddresses` whenever a new host is added, and both nix-darwin and NixOS configurations pick it up automatically.
