{pkgs, ...}: let
  setup = pkgs.callPackage ../setup.nix {};
  configure = setup.configure {
    restore_on_startup = true;
    soloist = {
      device_name = "synthetic fixture";
      directory = "/synthetic/soloist";
    };
  };
  refuses = settings: !(builtins.tryEval (setup.configure settings)).success;
in
  assert refuses {client_id = "not-public";};
  assert refuses {client_secret = "not-public";};
  assert refuses {soloist.api_key = "not-public";};
  assert refuses {soloist.api_key_file = "/not-public";};
  assert refuses {soloist.nested.value = "not-flat";};
    pkgs.runCommand "myx-setup-tests" {
      nativeBuildInputs = [pkgs.coreutils pkgs.jq];
    } ''
      set -euo pipefail
      umask 077
      root="$(realpath "$TMPDIR")/fixture"
      mkdir -m 700 "$root"
      cd "$root"
      count=0
      pass() { count=$((count + 1)); printf 'ok %s - %s\n' "$count" "$1"; }
      reject() {
        if timeout 35 "$@" > "$root/stdout" 2> "$root/stderr"; then
          printf 'unexpected success\n' >&2; exit 1
        fi
        ! grep -F 'synthetic-secret' "$root/stderr"
        ! grep -F '0123456789abcdef' "$root/stderr"
        [ "$(cat "$root/stderr")" = 'myx-setup: refused unsafe or invalid materialization' ]
        [ ! -s "$root/stdout" ]
      }
      runtime=${setup.runtime}
      configure=${configure}
      mkdir -p source/{bin,runtime} releases credentials
      printf '#!/bin/sh\nexit 99\n' > source/bin/myx
      chmod 700 source/bin/myx
      printf '{"synthetic":true}\n' > source/runtime/manifest.json
      printf 'synthetic asset\n' > source/runtime/asset
      source="$root/source"
      release="$root/releases/v1"
      [ "$($runtime "$source" "$release")" = "$release/bin/myx" ]
      cmp source/runtime/asset "$release/runtime/asset"
      [ "$(stat -c %h "$release/bin/myx")" = 1 ]
      pass 'runtime copies a public bundle without launching it'
      inode=$(stat -c %i "$release/bin/myx")
      $runtime "$source" "$release" > /dev/null
      [ "$inode" = "$(stat -c %i "$release/bin/myx")" ]
      pass 'runtime reuse is non-mutating'
      printf 'tamper' >> "$release/bin/myx"
      reject $runtime "$source" "$release"
      pass 'tampered binary refused'
      reject $runtime "$source" /nix/store/synthetic-myxtest
      pass 'store runtime refused'
      mkdir releases/unknown
      reject $runtime "$source" "$root/releases/unknown"
      pass 'unknown empty runtime not overwritten'
      ln -s "$release" releases/link
      reject $runtime "$source" "$root/releases/link"
      pass 'runtime destination symlink refused'
      $runtime "$source" "$root/releases/race" > first & a=$!
      $runtime "$source" "$root/releases/race" > second & b=$!
      wait "$a"; wait "$b"
      cmp first second
      pass 'concurrent runtime publication serializes'
      chmod 660 "$root/releases/race/runtime/manifest.json"
      reject $runtime "$source" "$root/releases/race"
      pass 'writable runtime manifest refused'
      chmod 600 "$root/releases/race/runtime/manifest.json"
      ln "$root/releases/race/bin/myx" hardlinked-binary
      reject $runtime "$source" "$root/releases/race"
      pass 'hardlinked runtime binary refused'
      chmod 777 releases
      reject $runtime "$source" "$root/releases/unsafe"
      chmod 700 releases
      pass 'unsafe runtime parent refused'
      reject $runtime "$source" "$root/releases/../escape"
      pass 'dotdot destination refused'

      printf 'synthetic-secret-one\n' > credentials/key
      printf '0123456789abcdef0123456789abcdef\r\n' > credentials/client
      ln -s "$root/credentials/key" key-alias
      ln -s "$root/credentials/client" client-alias
      unavailable="/myx-setup-uncreatable-$$"
      [ ! -e "$unavailable" ]
      reject $configure "$unavailable/config" "$root/credentials/missing" "$root/client-alias"
      [ ! -e "$unavailable" ]
      pass 'missing key preflight precedes uncreatable destination access'
      reject $configure "$unavailable/config" "$root/key-alias" "$root/credentials/missing"
      [ ! -e "$unavailable" ]
      pass 'missing client preflight precedes uncreatable destination access'
      chmod 644 credentials/key
      reject $configure "$root/not-created/config" "$root/key-alias" "$root/client-alias"
      [ ! -e "$root/not-created" ]
      chmod 600 credentials/key
      pass 'unsafe source metadata rejected before parent creation'
      directory="$root/config"
      $configure "$directory" "$root/key-alias" "$root/client-alias" > stdout
      [ ! -s stdout ]
      [ "$(stat -c %a "$directory")" = 700 ]
      [ "$(stat -c '%a:%h' "$directory/config.toml")" = 600:1 ]
      key=$(printf '%s\n' "$directory"/key-*)
      cmp credentials/key "$key"
      [ "$(stat -c '%a:%h' "$key")" = 600:1 ]
      grep -Fx 'client_id = "0123456789abcdef0123456789abcdef"' "$directory/config.toml"
      grep -Fx 'restore_on_startup = true' "$directory/config.toml"
      grep -Fx '[soloist]' "$directory/config.toml"
      grep -F "api_key_file = \"$key\"" "$directory/config.toml"
      ! grep -F 'synthetic-secret' "$directory/config.toml"
      pass 'private configuration and aliased age sources'
      inode=$(stat -c %i "$directory/config.toml")
      $configure "$directory" "$root/key-alias" "$root/client-alias"
      [ "$inode" = "$(stat -c %i "$directory/config.toml")" ]
      pass 'identical config and key reuse'
      printf 'synthetic-secret-two\n' > credentials/key
      $configure "$directory" "$root/key-alias" "$root/client-alias"
      [ -f "$key" ]
      keys=("$directory"/key-*)
      [ "''${#keys[@]}" = 2 ]
      pass 'rotation retains old immutable key'
      for size in 1024 16384; do
        printf "%0''${size}d" 0 > credentials/large-key
        $configure "$root/large-config" "$root/credentials/large-key" "$root/client-alias"
        found=0
        for candidate in "$root/large-config"/key-*; do
          if cmp -s credentials/large-key "$candidate"; then
            grep -F "api_key_file = \"$candidate\"" "$root/large-config/config.toml"
            found=1
          fi
        done
        [ "$found" = 1 ]
        pass "Soloist key with $size bytes is accepted"
      done
      cp "$root/large-config/config.toml" expected-large
      printf '%016385d' 0 > credentials/large-key
      reject $configure "$root/large-config" "$root/credentials/large-key" "$root/client-alias"
      cmp expected-large "$root/large-config/config.toml"
      pass 'Soloist key over 16 KiB rejected without config replacement'
      cp "$directory/config.toml" expected
      for invalid in empty control oversized; do
        case "$invalid" in
          empty) : > credentials/client ;;
          control) printf 'synthetic-secret\001' > credentials/client ;;
          oversized) printf '%0513d' 0 > credentials/client ;;
        esac
        reject $configure "$directory" "$root/key-alias" "$root/client-alias"
        cmp expected "$directory/config.toml"
        pass "invalid client $invalid preserves config without disclosure"
      done
      printf '0123456789abcdef0123456789abcdef' > credentials/client
      reject $configure "$directory" "$root/credentials/missing" "$root/client-alias"
      cmp expected "$directory/config.toml"
      pass 'missing key preserves config'
      : > credentials/key
      reject $configure "$directory" "$root/key-alias" "$root/client-alias"
      cmp expected "$directory/config.toml"
      pass 'empty key preserves config'
      printf 'synthetic-secret-two\n' > credentials/key
      chmod 644 credentials/key
      reject $configure "$directory" "$root/key-alias" "$root/client-alias"
      chmod 600 credentials/key
      pass 'wrong source mode refused'
      ln credentials/key source-hardlink
      reject $configure "$directory" "$root/key-alias" "$root/client-alias"
      rm source-hardlink
      pass 'source hardlink refused'
      mkdir unknown
      printf 'user data' > unknown/config.toml
      reject $configure "$root/unknown" "$root/key-alias" "$root/client-alias"
      [ "$(cat unknown/config.toml)" = 'user data' ]
      pass 'unmanaged directory preserved'
      ln -s "$directory" config-link
      reject $configure "$root/config-link" "$root/key-alias" "$root/client-alias"
      pass 'config directory symlink refused'
      chmod 644 "$directory/config.toml"
      reject $configure "$directory" "$root/key-alias" "$root/client-alias"
      chmod 600 "$directory/config.toml"
      pass 'wrong config mode refused'
      ln "$directory/config.toml" config-hardlink
      reject $configure "$directory" "$root/key-alias" "$root/client-alias"
      rm config-hardlink
      pass 'config hardlink refused'
      mv "$directory/config.toml" saved-config
      ln -s "$root/saved-config" "$directory/config.toml"
      reject $configure "$directory" "$root/key-alias" "$root/client-alias"
      rm "$directory/config.toml"
      mv saved-config "$directory/config.toml"
      pass 'config symlink refused'
      printf 'not managed\n' > "$directory/config.toml"
      reject $configure "$directory" "$root/key-alias" "$root/client-alias"
      cp expected "$directory/config.toml"
      pass 'unmarked config inside managed directory refused'
      chmod 644 "$directory/.myx-nix-managed"
      reject $configure "$directory" "$root/key-alias" "$root/client-alias"
      chmod 600 "$directory/.myx-nix-managed"
      pass 'wrong marker mode refused'
      chmod 644 "$key"
      reject $configure "$directory" "$root/key-alias" "$root/client-alias"
      chmod 600 "$key"
      pass 'wrong retained key mode refused'
      ln "$key" retained-hardlink
      reject $configure "$directory" "$root/key-alias" "$root/client-alias"
      rm retained-hardlink
      pass 'retained key hardlink refused'
      mv "$key" retained-key
      ln -s "$root/retained-key" "$key"
      reject $configure "$directory" "$root/key-alias" "$root/client-alias"
      rm "$key"
      mv retained-key "$key"
      pass 'retained key symlink refused'
      reject $configure "$directory" "$root/key-alias" "$root/credentials/missing"
      cmp expected "$directory/config.toml"
      pass 'missing client preserves config'
      printf 'synthetic-secret\001' > credentials/key
      reject $configure "$directory" "$root/key-alias" "$root/client-alias"
      cmp expected "$directory/config.toml"
      pass 'control in secret preserves config'
      printf '%016385d' 0 > credentials/key
      reject $configure "$directory" "$root/key-alias" "$root/client-alias"
      cmp expected "$directory/config.toml"
      pass 'oversized source preserves config'
      printf 'synthetic-secret-two\n' > credentials/key
      $configure "$directory" "$root/key-alias" "$root/client-alias" & a=$!
      $configure "$directory" "$root/key-alias" "$root/client-alias" & b=$!
      wait "$a"; wait "$b"
      cmp expected "$directory/config.toml"
      pass 'concurrent config publication serializes'
      timeout 35 /usr/bin/lockf -k -t 30 "$root/.myx-setup.lock" \
        ${pkgs.bash}/bin/bash -c 'touch "$1"; while [ ! -e "$2" ]; do sleep 0.05; done' \
        unused "$root/locked" "$root/unlock" & holder=$!
      for attempt in $(seq 1 100); do
        [ ! -e locked ] || break
        sleep 0.05
      done
      [ -e locked ]
      timeout 35 $configure "$directory" "$root/key-alias" "$root/client-alias" & waiter=$!
      sleep 0.2
      printf 'synthetic-secret-three\n' > credentials/key
      touch unlock
      wait "$holder"; wait "$waiter"
      keys=("$directory"/key-*)
      [ "''${#keys[@]}" = 3 ]
      found=0
      for candidate in "''${keys[@]}"; do
        if cmp -s credentials/key "$candidate"; then
          grep -F "api_key_file = \"$candidate\"" "$directory/config.toml"
          found=1
        fi
      done
      [ "$found" = 1 ]
      pass 'waiting activation reads rotated sources after lock acquisition'
      printf '1..%s\n' "$count"
      touch "$out"
    ''
