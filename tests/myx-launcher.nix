{
  lib,
  pkgs,
}: let
  release = pkgs.runCommand "myx-synthetic-public-release.tar.gz" {nativeBuildInputs = [pkgs.gnutar];} ''
    mkdir -p myx-macos-aarch64/{bin,runtime}
    cat > myx-macos-aarch64/bin/myx <<'FIXTURE'
    #!${pkgs.runtimeShell}
    printf '%s\0' "$@" > "$MYX_TEST_ARGV"
    printf '%s\n' 'myx launcher fixture 0.5.0-preview.1'
    FIXTURE
    chmod 0755 myx-macos-aarch64/bin/myx
    printf '%s\n' '{"fixture": "public release, no audio or SDK"}' > myx-macos-aarch64/runtime/manifest.json
    tar -czf "$out" myx-macos-aarch64
  '';
  directory = "/nonexistent-myx-launcher-fixture/managed";
  package = (pkgs.callPackage ../lib/myx-package.nix {
    configuration = {
      inherit directory;
      settings = {
        restore_on_startup = true;
        soloist.device_name = "myx fixture";
      };
      keySource = "/nonexistent-myx-launcher-fixture/age-key";
      clientIdSource = "/nonexistent-myx-launcher-fixture/age-client-id";
    };
  }).overrideAttrs {src = release;};
  managed = args: {inherit args;};
  custom = args: {
    inherit args;
    explicit = true;
  };
  blocked = args: {
    inherit args;
    succeeds = false;
  };
  cases = [
    (managed ["daemon" "stop"])
    (managed ["daemon" "status"])
    (managed ["service" "status"])
    (managed ["service" "uninstall"])
    (managed ["--json" "daemon" "status"])
    (managed ["daemon" "--non-interactive" "status" "--json"])
    (managed ["--non-interactive" "service" "--json" "status"])
    (managed ["service" "uninstall" "--non-interactive"])
    (managed ["--help"])
    (managed ["-h"])
    (managed ["--version"])
    (managed ["-V"])
    (managed ["daemon" "restart" "--help"])
    (managed ["service" "--help"])
    (custom ["--config" "/public fixture/quoted' config.toml" "daemon" "restart"])
    (custom ["daemon" "--config=/public fixture/config.toml" "start"])
    (custom ["--non-interactive" "--config" "/public fixture/config.toml" "--" "uri with spaces 'quotes' * $ and
newline"])
    (blocked [])
    (blocked ["daemon" "run"])
    (blocked ["daemon" "start"])
    (blocked ["daemon" "restart"])
    (blocked ["service" "install"])
    (blocked ["--headless" "--duration" "1" "--volume" "50"])
    (blocked ["daemon" "--output" "status"])
    (blocked ["daemon" "--output=status"])
    (blocked ["--output" "daemon" "status"])
    (blocked ["--output=daemon" "status"])
    (blocked ["daemon" "--duration" "status"])
    (blocked ["daemon" "--duration=status"])
    (blocked ["daemon" "--volume" "stop"])
    (blocked ["daemon" "--volume=stop"])
    (blocked ["--output" "--help"])
    (blocked ["--output" "--version"])
    (blocked ["--output" "--config=not-an-option"])
    (blocked ["--" "--help"])
    (blocked ["--" "--config=not-an-option"])
    (blocked ["--" "daemon" "stop"])
  ];
  runCase = index: test: let
    succeeds = test.succeeds or true;
    expected = lib.optionals (!(test.explicit or false)) ["--config" "${directory}/config.toml"] ++ test.args;
  in ''
    printf '%s\n' ${lib.escapeShellArg "case ${toString (index + 1)}: ${builtins.toJSON test.args}"}
    rm -f "$MYX_TEST_ARGV"
    ${
      if succeeds
      then ''
        if ! ${package}/bin/myx ${lib.escapeShellArgs test.args} > stdout 2> stderr; then
          cat stderr >&2
          exit 1
        fi
        printf '%s\0' ${lib.escapeShellArgs expected} > expected-argv
        cmp expected-argv "$MYX_TEST_ARGV"
        printf '%s\n' 'myx launcher fixture 0.5.0-preview.1' > expected-stdout
        cmp expected-stdout stdout
        test ! -s stderr
      ''
      else ''
        if ${package}/bin/myx ${lib.escapeShellArgs test.args} > stdout 2> stderr; then
          printf '%s\n' 'unexpected credential-free launch' >&2
          exit 1
        fi
        test ! -e "$MYX_TEST_ARGV"
        test ! -s stdout
        printf '%s\n' 'myx-setup: refused unsafe or invalid materialization' > expected-stderr
        cmp expected-stderr stderr
      ''
    }
  '';
in
  pkgs.runCommand "myx-launcher-tests" {} ''
    set -eu
    umask 077
    root="$(pwd -P)/private-launcher-test"
    mkdir -m 0700 "$root"
    export HOME="$root/home"
    export XDG_DATA_HOME="$root/data"
    export MYX_TEST_ARGV="$root/argv"
    mkdir -m 0700 "$HOME" "$XDG_DATA_HOME"
    ${lib.concatStrings (lib.imap0 runCase cases)}
    runtime="$XDG_DATA_HOME/myx/runtime/${package.version}"
    test -f "$runtime/bin/myx"
    test ! -L "$runtime/bin/myx"
    test -f "$runtime/runtime/manifest.json"
    cmp ${package}/share/myx-macos-aarch64/bin/myx "$runtime/bin/myx"
    printf '%s\n' '${toString (builtins.length cases)} launcher cases passed' > "$out"
  ''
