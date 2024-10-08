# Dotfiles

This directory contains the dotfiles for my mac

## Installation

Install Nix Package Manager

```bash
sh <(curl -L https://nixos.org/nix/install)
```

Pull the dotfiles

```bash
cd ~
nix-env -iA nixos.git
git clone https://github.com/ushiradineth/dotfiles.git
cd dotfiles
```

Install the packages


```bash
cd ~/dotfiles/nix
nix run nix-darwin --extra-experimental-features "nix-command flakes" -- switch --flake ~/dotfiles/nix#m2
```

then use GNU stow to create symlinks

```bash
cd ~/dotfiles
stow .
```

