{
  lib,
  writeShellScript,
  coreutils,
  diffutils,
  jq,
  formats,
}: let
  # runtime SOURCE DESTINATION prints DESTINATION/bin/myx; configure SETTINGS
  # returns a silent script taking DIRECTORY KEY_SOURCE CLIENT_ID_SOURCE.
  common = ''
    set +x
    set +a
    set -euo pipefail
    export PATH=${lib.makeBinPath [coreutils diffutils]}
    umask 077
    uid=$(id -u)
    absolute() {
      case "$1" in *$'\n'*|*$'\r'*) fail ;; esac
      case "$1" in /) ;; /*) case "$1/" in *//*|*/../*|*/./*) fail ;; esac ;; *) fail ;; esac
    }
    outside_store() { case "$1" in /nix/store|/nix/store/*) fail ;; esac; }
    parents() {
      absolute "$1"
      local part path="" owner mode
      local -a parts
      IFS=/ read -r -a parts <<< "$1"
      for part in "''${parts[@]}"; do
        [ -n "$part" ] || continue
        path="$path/$part"
        [ ! -L "$path" ] || fail
        if [ ! -e "$path" ]; then mkdir -m 700 -- "$path"; fi
        [ -d "$path" ] || fail
        read -r owner mode < <(stat -c '%u %a' -- "$path")
        [ "$owner" = 0 ] || [ "$owner" = "$uid" ] || fail
        if (( (8#$mode & 022) != 0 )); then
          [ "$owner" = 0 ] || fail
          (( (8#$mode & 01000) != 0 )) || fail
          case "$path" in /tmp|/private/tmp|/var/tmp|/private/var/tmp) ;; *) fail ;; esac
        fi
      done
    }
    private() {
      [ ! -L "$1" ] && [ -f "$1" ] || fail
      [ "$(stat -c '%u:%a:%h' -- "$1")" = "$uid:600:1" ] || fail
    }
  '';
  sourceMetadata = ''
    source_file() {
      absolute "$1"
      local canonical
      canonical=$(realpath -e -- "$1") || fail
      outside_store "$canonical"
      private "$canonical"
      [ "$(stat -c %s -- "$canonical")" -le 16384 ] || fail
      printf '%s\n' "$canonical"
    }
  '';
  locked = name: count: destination: body: let
    metadata = lib.optionalString (name == "configure") sourceMetadata;
    worker = writeShellScript "myx-${name}-locked" (common
      + ''        fail() { exit 1; }
      ''
      + metadata
      + body);
  in
    writeShellScript "myx-${name}" (''
        exec 3>&2 2>/dev/null
      ''
      + common
      + metadata
      + ''
        fail() { printf '%s\n' 'myx-setup: refused unsafe or invalid materialization' >&3; exit 1; }
        set -E
        trap fail ERR
        [ "$#" = ${toString count} ] || fail
        destination=${destination}
        absolute "$destination"
        outside_store "$destination"
        ${lib.optionalString (name == "configure") ''
          source_file "$2" > /dev/null
          source_file "$3" > /dev/null
        ''}
        parent=$(dirname -- "$destination")
        parents "$parent"
        lock="$parent/.myx-setup.lock"
        if [ ! -e "$lock" ] && [ ! -L "$lock" ]; then
          (set -C; : > "$lock") 2>/dev/null || :
        fi
        private "$lock"
        /usr/bin/lockf -k -t 30 "$lock" ${worker} "$@" || fail
      '');
in {
  runtime = locked "runtime" 2 ''"$2"'' ''
    source=$1 destination=$2
    absolute "$source"
    check_release() {
      local root=$1 file owner mode links
      [ ! -L "$root" ] && [ -d "$root" ] || fail
      parents "$root"
      for file in "$root/bin" "$root/runtime"; do
        [ ! -L "$file" ] && [ -d "$file" ] || fail
        parents "$file"
      done
      for file in "$root/bin/myx" "$root/runtime/manifest.json"; do
        [ ! -L "$file" ] && [ -f "$file" ] || fail
        read -r owner mode links < <(stat -c '%u %a %h' -- "$file")
        [ "$owner" = "$uid" ] && [ "$links" = 1 ] || fail
        (( (8#$mode & 022) == 0 )) || fail
      done
      [ -x "$root/bin/myx" ] || fail
      cmp -s -- "$source/bin/myx" "$root/bin/myx" || fail
      cmp -s -- "$source/runtime/manifest.json" "$root/runtime/manifest.json" || fail
    }
    # Myx's native self-reader checks the full inventory before executing it.
    if [ -e "$destination" ] || [ -L "$destination" ]; then
      check_release "$destination"
    else
      temporary=$(mktemp -d "$(dirname -- "$destination")/.myx-runtime-XXXXXXXX")
      trap 'rm -rf -- "$temporary"' EXIT
      cp -R -- "$source/." "$temporary/"
      chmod -R u+w -- "$temporary"
      check_release "$temporary"
      mv -T -n -- "$temporary" "$destination"
      check_release "$destination"
    fi
    printf '%s/bin/myx\n' "$destination"
  '';
  configure = settings:
    assert !(settings ? client_id || settings ? client_secret);
    assert !(settings.soloist ? api_key || settings.soloist ? api_key_file);
    assert lib.all (value: !(builtins.isAttrs value || builtins.isList value)) (builtins.attrValues settings.soloist); let
      toml = formats.toml {};
      root = toml.generate "myx-public-root.toml" (removeAttrs settings ["soloist"]);
      soloist = toml.generate "myx-public-soloist.toml" settings.soloist;
    in
      locked "configure" 3 ''"$1"'' ''
        marker='# Managed by Nix for Myx.'
        directory=$1
        parents "$directory"
        [ "$(stat -c '%u:%a' -- "$directory")" = "$uid:700" ] || fail
        key_source=$(source_file "$2")
        client_source=$(source_file "$3")
        quote_credential() {
          ${jq}/bin/jq -Rse --argjson limit "''${2:-512}" '
            sub("[\r\n]+$"; "") |
            select(length > 0 and length <= $limit) |
            select(test("[\u0000-\u001f]") | not)
          ' < "$1"
        }
        quote_credential "$key_source" 16384 > /dev/null
        export -n client
        client=$(quote_credential "$client_source")
        owner="$directory/.myx-nix-managed"
        if [ -e "$owner" ] || [ -L "$owner" ]; then
          private "$owner"
          printf '%s\n' "$marker" | cmp -s - "$owner" || fail
        else
          [ -z "$(ls -A -- "$directory")" ] || fail
          printf '%s\n' "$marker" > "$owner"
        fi
        config="$directory/config.toml"
        if [ -e "$config" ] || [ -L "$config" ]; then
          private "$config"
          IFS= read -r first < "$config"
          [ "$first" = "$marker" ] || fail
        fi
        key=
        shopt -s nullglob
        for existing in "$directory"/key-*; do
          private "$existing"
          if cmp -s -- "$key_source" "$existing"; then key=$existing; fi
        done
        if [ -z "$key" ]; then
          key=$(mktemp "$directory/key-XXXXXXXX")
          cat -- "$key_source" > "$key"
        fi
        temporary=$(mktemp "$directory/.config-XXXXXXXX")
        trap 'rm -f -- "$temporary"' EXIT
        {
          printf '%s\nclient_id = %s\n' "$marker" "$client"
          cat ${root}
          printf '\n[soloist]\napi_key_file = '
          printf '%s' "$key" | ${jq}/bin/jq -Rs .
          cat ${soloist}
        } > "$temporary"
        private "$key"
        quote_credential "$key" 16384 > /dev/null
        private "$key_source"
        private "$client_source"
        cmp -s -- "$key_source" "$key" || fail
        quote_credential "$client_source" | cmp -s - <(printf '%s\n' "$client") || fail
        if [ -f "$config" ] && cmp -s -- "$temporary" "$config"; then exit 0; fi
        mv -T -f -- "$temporary" "$config"
      '';
}
