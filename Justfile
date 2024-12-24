# just is a command runner, Justfile is very similar to Makefile, but simpler.

# List all the just commands
default:
  @just --list

############################################################################
#
#  Darwin desktop related commands
#
############################################################################

[macos]
[group('shu')]
build:
  nix build .#darwinConfigurations.shu.system \
    --extra-experimental-features 'nix-command flakes'

  ./result/sw/bin/darwin-rebuild switch --flake .#shu

[macos]
[group('shu')]
debug:
  nix build .#darwinConfigurations.shu.system --show-trace --verbose \
    --extra-experimental-features 'nix-command flakes'

  ./result/sw/bin/darwin-rebuild switch --flake .#shu --show-trace --verbose

############################################################################
#
#  Linux server related commands
#
############################################################################

[linux]
[group('shulab')]
build:
  nix build .#nixosConfigurations.shulab.config.system.build.toplevel \
    --extra-experimental-features 'nix-command flakes'

  sudo ./result/bin/switch-to-configuration switch

[linux]
[group('shulab')]
debug:
  nix build .#nixosConfigurations.shulab.config.system.build.toplevel --show-trace --verbose \
    --extra-experimental-features 'nix-command flakes'

  sudo ./result/bin/switch-to-configuration switch --show-trace --verbose

############################################################################
#
#  nix related commands
#
############################################################################

# Update all the flake inputs
[group('nix')]
up:
  nix flake update

# Update specific input
[group('nix')]
upp input:
  nix flake update {{input}}

# List all generations of the system profile
[group('nix')]
history:
  nix profile history --profile /nix/var/nix/profiles/system

# Open a nix shell with the flake
[group('nix')]
repl:
  nix repl -f flake:nixpkgs

# remove all generations older than 7 days
# on darwin, you may need to switch to root user to run this command
[group('nix')]
clean:
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

# Garbage collect all unused nix store entries
[group('nix')]
gc:
  # garbage collect all unused nix store entries(system-wide)
  sudo nix-collect-garbage --delete-older-than 7d
  # garbage collect all unused nix store entries(for the user - home-manager)
  # https://github.com/NixOS/nix/issues/8508
  nix-collect-garbage --delete-older-than 7d

[group('nix')]
fmt:
  # format the nix files in this repo
  nix fmt

# Show all the auto gc roots in the nix store
[group('nix')]
gcroot:
  ls -al /nix/var/nix/gcroots/auto/

