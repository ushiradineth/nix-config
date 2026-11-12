{pkgs}: let
  semgrepPython = pkgs.python3.withPackages (p: [p.pyyaml]);
  semgrepPackage = import ../package.nix {inherit pkgs;};
in
  pkgs.runCommand "semgrep-local-tests" {
    src = ../.;
    nativeBuildInputs = [semgrepPython pkgs.semgrep];
    SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    SEMGREP_LOCAL_BINARY = "${semgrepPackage}/bin/semgrep-local";
  } ''
    export HOME="$TMPDIR/home"
    export SEMGREP_SETTINGS_FILE="$TMPDIR/settings.yml"
    # stdenv seeds offline sentinel CA paths; initialize the native library locally.
    export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
    export NIX_SSL_CERT_FILE="$SSL_CERT_FILE"
    export SEMGREP_SEND_METRICS=off SEMGREP_ENABLE_VERSION_CHECK=0 CI=true
    export PYTHONDONTWRITEBYTECODE=1
    mkdir -p "$HOME"
    cd "$src"
    semgrep scan --test --config baseline --strict --metrics=off \
      --disable-version-check --disable-nosem --no-rewrite-rule-ids baseline
    python3 tests/scanner-test.py
    touch "$out"
  ''
