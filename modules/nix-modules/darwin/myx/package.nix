{
  lib,
  stdenvNoCC,
  fetchurl,
  gnutar,
  callPackage,
  runtimeShell,
  configuration ? null,
}: let
  version = "0.5.0-preview.5";
  archiveHash = "sha256-y4JGlbWjPC4PN83IKG4ND9MXA/f/pb29rrl4Kt1WYV4=";
  setup = callPackage ./setup.nix {};
  configure = lib.optionalString (configuration != null) ''
    if [ "$custom_config" = 0 ]; then
      if [ "$metadata_only" = 0 ] && [ "$recovery_only" = 0 ]; then
        ${setup.configure configuration.settings} \
          ${lib.escapeShellArg configuration.directory} \
          ${lib.escapeShellArg configuration.keySource} \
          ${lib.escapeShellArg configuration.clientIdSource}
      fi
      set -- --config ${lib.escapeShellArg "${configuration.directory}/config.toml"} "$@"
    fi
  '';
in
  stdenvNoCC.mkDerivation {
    pname = "myx";
    inherit version;
    src = fetchurl {
      url = "https://github.com/ushiradineth/myx/releases/download/v${version}/myx-macos-aarch64.tar.gz";
      hash = archiveHash;
    };
    nativeBuildInputs = [gnutar];
    dontUnpack = true;
    dontFixup = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/bin" "$out/share"
      tar -xzf "$src" -C "$out/share"
      cat > "$out/bin/myx" <<'MYX_LAUNCHER'
      #!${runtimeShell}
      set -eu
      custom_config=0
      metadata_only=0
      recovery_only=0
      skip_value=0
      positional_only=0
      command_group=
      command_action=
      for argument in "$@"; do
        if [ "$skip_value" = 1 ]; then
          skip_value=0
          continue
        fi
        if [ "$positional_only" = 0 ]; then
          case "$argument" in
            --) positional_only=1; continue ;;
            --config) custom_config=1; skip_value=1; continue ;;
            --config=*) custom_config=1; continue ;;
            --duration|--volume|--output) skip_value=1; continue ;;
            --help|-h|--version|-V) metadata_only=1; continue ;;
            -*) continue ;;
          esac
        fi
        if [ -z "$command_group" ]; then
          if [ "$positional_only" = 0 ]; then
            command_group="$argument"
          else
            command_group=positional
          fi
        elif [ -z "$command_action" ]; then
          command_action="$argument"
        fi
      done
      case "$command_group:$command_action" in
        daemon:stop|daemon:status|service:status|service:uninstall) recovery_only=1 ;;
      esac
      ${configure}
      destination="''${XDG_DATA_HOME:-$HOME/.local/share}/myx/runtime/${version}"
      binary="$(${setup.runtime} @MYX_BUNDLE@ "$destination")"
      exec "$binary" "$@"
      MYX_LAUNCHER
      substituteInPlace "$out/bin/myx" --replace-fail @MYX_BUNDLE@ "$out/share/myx-macos-aarch64"
      chmod 0755 "$out/bin/myx"
      runHook postInstall
    '';
    meta = {
      description = "Daemon-owned Spotify terminal player with a private processed Mac runtime";
      homepage = "https://github.com/ushiradineth/myx";
      license = lib.licenses.mit;
      platforms = ["aarch64-darwin"];
      mainProgram = "myx";
    };
  }
