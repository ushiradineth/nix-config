# ❄️ Nix Configuration

This repository contains my nix configuration for my MacOS machine and NixOS homelab server.

## Reference

This repository drew significant inspiration from the outstanding work done by
[Ryan Yin](https://github.com/ryan4yin). The following repositories were referenced:

- [nix-config](https://github.com/ryan4yin/nix-config)
- [nix-darwin-kickstarter](https://github.com/ryan4yin/nix-darwin-kickstarter)

## Installation on MacOS (shu)

### Install Nix Package Manager

```bash
sh <(curl -L https://nixos.org/nix/install)
```

### Pull the configuration

```bash
cd ~
nix-shell -p git
git clone https://github.com/ushiradineth/nix-config.git
cd nix-config
```

### Install Xcode Command Line Tools

```bash
xcode-select --install
```

### Enable Rosetta

```bash
sudo softwareupdate --install-rosetta --agree-to-license
```

### Build nix flake

```bash
cd ~/nix-config
nix-shell -p just
just build-shu
```

## Installation on Linux (shulab)

### Install Nix Package Manager

```bash
sh <(curl -L https://nixos.org/nix/install)
```

### Pull the configuration

```bash
cd ~
nix-shell -p git
git clone https://github.com/ushiradineth/nix-config.git
cd nix-config
```

### Build nix flake

```bash
cd ~/nix-config
nix-shell -p just
just build-shulab
```

## Configuration Structure

```bash
› tree
.
├── flake.nix # Main entry point
├── home # home-manager configurations
│   ├── base
│   ├── darwin
│   ├── linux
├── hosts  # hosts configurations
│   ├── shu
│   └── shulab
├── Justfile
├── lib # helper functions
├── modules # Modules for extending configurations
│   ├── darwin
│   ├── linux
├── outputs # Architecture specific outputs
│   ├── aarch64-darwin
│   └── x86_64-linux
└── vars # Variables for dynamic configurations
```
