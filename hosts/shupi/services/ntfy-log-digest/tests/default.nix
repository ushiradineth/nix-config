{pkgs}:
pkgs.runCommand "ntfy-log-digest-tests" {
  src = ../.;
  nativeBuildInputs = [pkgs.python3];
} ''
  export HOME="$TMPDIR/home"
  export PYTHONDONTWRITEBYTECODE=1
  mkdir -p "$HOME"
  cp -R "$src" source
  chmod -R u+w source
  cd source
  python3 tests/journal-summary-test.py
  touch "$out"
''
