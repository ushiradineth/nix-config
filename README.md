# Dotfiles

This directory contains the dotfiles for my mac

## Requirements

Ensure that the following installed on the system before use

### Git

```bash
brew install git
```

### Stow

```bash
brew install stow
```

## Installation

First, check out the dotfiles repo in your $HOME directory using git

```bash
cd
git clone https://github.com/ushiradineth/dotfiles.git
cd dotfiles
```

then use GNU stow to create symlinks

```bash
stow .
```

## Brew Packages

Run the following command to install all brew packages

```bash
xargs brew install < brew.txt
```

Run the following command to update the brew package list

```bash
cd ~/dotfiles
brew list > brew.txt
```

## Reference

- [Stow has forever changed the way I manage my dotfiles - Dreams of Autonomy](https://www.youtube.com/watch?v=y6XCebnB9gs)
