# Flake Outputs

This directory contains host output composition for the flake using `flake-parts`.

- Host outputs live in `outputs/`.
- Shared host builders live in `lib/hosts.nix`.
- Linux/Darwin `default.nix` use `scanPaths` to auto-import host files.
- Colmena hosts must be manually registered in `outputs/colmena/default.nix`.

## Overview

```bash
outputs/
├── README.md
├── linux/
│   ├── default.nix   # aggregates nixosConfigurations
│   ├── shulab.nix
│   └── shuos.nix
├── darwin/
│   ├── default.nix   # aggregates darwinConfigurations
│   └── shu.nix
└── colmena/
    ├── default.nix   # colmena meta + node aggregation
    ├── shupi.nix
    └── shutm.nix
```
