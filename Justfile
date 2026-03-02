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
# Default skips managed installs (Homebrew + pnpm globals).
# Pass --with-installs to enable managed installs for this run.
[macos]
[group('macos')]
build *flags:
  #!/usr/bin/env bash
  set -euo pipefail

  should_enable_managed_installs=0
  for flag in {{flags}}; do
    case "$flag" in
      --with-installs|with-installs)
        should_enable_managed_installs=1
        ;;
      *)
        echo "Unknown build flag: $flag" >&2
        echo "Supported: --with-installs" >&2
        exit 1
        ;;
    esac
  done

  if [ "$should_enable_managed_installs" -eq 1 ]; then
    export NIXCFG_ENABLE_MANAGED_INSTALLS=1
    impure_flag=(--impure)
  else
    impure_flag=()
  fi

  nix run nixpkgs#nix-output-monitor -- build .#darwinConfigurations.$(hostname).system \
    --extra-experimental-features 'nix-command flakes' "${impure_flag[@]}"

  nix run nixpkgs#nvd -- diff /nix/var/nix/profiles/system ./result

  sudo -E ./result/sw/bin/darwin-rebuild switch --flake .#$(hostname) "${impure_flag[@]}"

# Build and show closure diff without switching.
[macos]
[group('macos')]
build-dry:
  nix run nixpkgs#nix-output-monitor -- build .#darwinConfigurations.$(hostname).system \
    --extra-experimental-features 'nix-command flakes'

  nix run nixpkgs#nvd -- diff /nix/var/nix/profiles/system ./result

# Build in debug mode.
[macos]
[group('macos')]
debug:
  nix run nixpkgs#nix-output-monitor -- build .#darwinConfigurations.$(hostname).system --show-trace --verbose \
    --extra-experimental-features 'nix-command flakes'

  sudo -E ./result/sw/bin/darwin-rebuild switch --flake .#$(hostname) --show-trace --verbose

############################################################################
#
#  Linux server related commands
#
############################################################################

# Build in release mode.
# Default skips managed installs (Homebrew + pnpm globals).
# Pass --with-installs to enable managed installs for this run.
[linux]
[group('linux')]
build *flags:
  #!/usr/bin/env bash
  set -euo pipefail

  should_enable_managed_installs=0
  for flag in {{flags}}; do
    case "$flag" in
      --with-installs|with-installs)
        should_enable_managed_installs=1
        ;;
      *)
        echo "Unknown build flag: $flag" >&2
        echo "Supported: --with-installs" >&2
        exit 1
        ;;
    esac
  done

  if [ "$should_enable_managed_installs" -eq 1 ]; then
    export NIXCFG_ENABLE_MANAGED_INSTALLS=1
    impure_flag=(--impure)
  else
    impure_flag=()
  fi

  nix run nixpkgs#nix-output-monitor -- build .#nixosConfigurations.$(hostname).config.system.build.toplevel \
    --quiet --extra-experimental-features 'nix-command flakes' "${impure_flag[@]}"

  nix run nixpkgs#nvd -- diff /run/current-system ./result

  sudo nixos-rebuild switch --flake .#$(hostname) --quiet "${impure_flag[@]}"

# Build and show closure diff without switching.
[linux]
[group('linux')]
build-dry:
  nix run nixpkgs#nix-output-monitor -- build .#nixosConfigurations.$(hostname).config.system.build.toplevel \
    --quiet --extra-experimental-features 'nix-command flakes'

  nix run nixpkgs#nvd -- diff /run/current-system ./result

# Build in debug mode.
[linux]
[group('linux')]
debug:
  nix run nixpkgs#nix-output-monitor -- build .#nixosConfigurations.$(hostname).config.system.build.toplevel --show-trace --verbose \
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

# Garbage collect all unused nix store entries.
[group('nix')]
cleanup:
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 7d
  sudo nix-collect-garbage --delete-older-than 7d
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

# Dry-run deployment to remote machine
[group('remote')]
deploy-dry tag:
  colmena apply dry-activate --on '@{{tag}}' --verbose --show-trace --impure --build-on-target
