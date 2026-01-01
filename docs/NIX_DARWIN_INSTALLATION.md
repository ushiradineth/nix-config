# Nix-darwin Installation Guide (shu)

## Install Nix Package Manager

```bash
sh <(curl -L https://nixos.org/nix/install)
```

## Pull the configuration

```bash
cd ~
nix-shell -p git
git clone https://github.com/ushiradineth/nix-config.git
cd nix-config
```

## Install Xcode Command Line Tools

```bash
xcode-select --install
```

## Enable Rosetta

```bash
sudo softwareupdate --install-rosetta --agree-to-license
```

## Build nix flake

```bash
cd ~/nix-config
nix-shell -p just
just build
```
