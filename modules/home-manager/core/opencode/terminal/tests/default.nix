{
  pkgs,
  nodeTypes,
}: let
  terminalTestProcess = pkgs.writeShellScript "opencode-terminal-test-process" ''
    printf 'test-process-%s\n' "$2"
  '';
in
  pkgs.runCommand "opencode-terminal-tests" {
    src = ../../..;
    nativeBuildInputs = [pkgs.nodejs pkgs.tmux pkgs.typescript] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [pkgs.procps];
    OPENCODE_TERMINAL_PS =
      if pkgs.stdenv.isDarwin
      then "${terminalTestProcess}"
      else "${pkgs.procps}/bin/ps";
  } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    node --experimental-strip-types --input-type=module -e 'await import("file://${../config}/plugins/terminal-context.ts")'
    tsc --project "$src/opencode/terminal/tests/opencode-terminal.tsconfig.json" --typeRoots ${nodeTypes}
    node --test "$src/opencode/terminal/tests/opencode-terminal.test.mts" "$src/opencode/terminal/tests/tmux-terminal.test.mts"
    touch "$out"
  ''
