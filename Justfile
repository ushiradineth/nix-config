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
  nix build .#nixosConfigurations.$(hostname).config.system.build.toplevel \
    --quiet --extra-experimental-features 'nix-command flakes'

  sudo nixos-rebuild switch --flake .#$(hostname) --quiet

# Build in debug mode.
[linux]
[group('linux')]
debug:
  nix build .#nixosConfigurations.$(hostname).config.system.build.toplevel --show-trace --verbose \
    --extra-experimental-features 'nix-command flakes'

  sudo nixos-rebuild switch --flake .#$(hostname) --show-trace --verbose

############################################################################
#
#  Nix related commands
#
############################################################################

# Update all the flake inputs.
[group('nix')]
up:
  nix flake update

# Update specific input
# Usage: just upp nixpkgs
[group('nix')]
upp input:
  nix flake update {{input}}

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
  nix store optimise

# Format source files in this repo.
[group('nix')]
fmt:
  nix fmt

# Run flake checks including pre-commit hooks.
[group('nix')]
check:
  nix flake check --all-systems --extra-experimental-features 'nix-command flakes'

############################################################################
#
#  Remote deployment
#
############################################################################

# Initialize remote machine
[group('remote')]
init hostname phases='disko,install,reboot':
  nix run github:nix-community/nixos-anywhere -- \
    --flake .#{{hostname}} \
    --target-host root@{{hostname}} \
    --option experimental-features "nix-command flakes" \
    --phases {{phases}}

# Deploy to remote machine
[group('remote')]
deploy tag:
  colmena apply --on '@{{tag}}' --verbose --show-trace --impure --build-on-target
