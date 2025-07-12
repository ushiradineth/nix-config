# just is a command runner, Justfile is very similar to Makefile, but simpler.

# List all the just commands.
default:
  @just --list

############################################################################
#
#  Darwin desktop related commands
#
############################################################################

# Build in release mode.
[macos]
[group('macos')]
build:
  nix build .#darwinConfigurations.$(hostname).system \
    --extra-experimental-features 'nix-command flakes'

  sudo -E ./result/sw/bin/darwin-rebuild switch --flake .#$(hostname)

# Build in debug mode.
[macos]
[group('macos')]
debug:
  nix build .#darwinConfigurations.$(hostname).system --show-trace --verbose \
    --extra-experimental-features 'nix-command flakes'

  sudo -E ./result/sw/bin/darwin-rebuild switch --flake .#$(hostname) --show-trace --verbose

############################################################################
#
#  Linux server related commands
#
############################################################################

# Build in release mode.
[linux]
[group('linux')]
build:
  nix build .#nixosConfigurations.$(hostname).config.system.build.toplevel --quiet
  sudo nixos-rebuild switch --flake .#$(hostname) --quiet

# Build in debug mode.
[linux]
[group('linux')]
debug:
  nix build .#nixosConfigurations.$(hostname).config.system.build.toplevel --show-trace --verbose
  sudo nixos-rebuild switch --flake .#$(hostname) --show-trace --verbose

############################################################################
#
#  nix related commands
#
############################################################################

# Update all the flake inputs.
[group('nix')]
up:
  nix flake update

# List all generations of the system profile.
[group('nix')]
history:
  nix profile history --profile /nix/var/nix/profiles/system

# Remove all generations older than 7 days. On darwin, you may need to switch to root user to run this command.
[group('nix')]
clean:
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

# Garbage collect all unused nix store entries.
[group('nix')]
gc:
  # garbage collect all unused nix store entries(system-wide)
  sudo nix-collect-garbage --delete-older-than 7d
  # garbage collect all unused nix store entries(for the user - home-manager)
  # https://github.com/NixOS/nix/issues/8508
  nix-collect-garbage --delete-older-than 7d

# Format the nix files in this repo.
[group('nix')]
fmt:
  nix fmt .
