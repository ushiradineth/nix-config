{
  pkgs,
  nodeTypes,
}: let
  solidJS = pkgs.fetchurl {
    url = "https://registry.npmjs.org/solid-js/-/solid-js-1.9.17.tgz";
    hash = "sha512-4GAmLOWPfNV8H9Jfn2LSFTpNEG6jiOKPiwd5lnLGQtehHaX6l3TOLzJqQ7mqwB/3k1Yy3zyumFVopmc/tm34ow==";
  };
  cssTypes = pkgs.fetchurl {
    url = "https://registry.npmjs.org/csstype/-/csstype-3.2.3.tgz";
    hash = "sha512-z1HGKcYy2xA8AGQfwrn0PAy+PB7X/GSj3UVJW9qKyn43xWa+gl5nXmU4qqLMRzWVLFC8KusUX8T/0kCiOYpAIQ==";
  };
  terminalTestProcess = pkgs.writeShellScript "opencode-terminal-test-process" ''
    printf 'test-process-%s\n' "$2"
  '';
in
  pkgs.runCommand "opencode-terminal-tests" {
    src = ../../..;
    nativeBuildInputs = [pkgs.nodejs pkgs.tmux pkgs.typescript pkgs.gnutar] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [pkgs.procps];
    OPENCODE_TERMINAL_PS =
      if pkgs.stdenv.isDarwin
      then "${terminalTestProcess}"
      else "${pkgs.procps}/bin/ps";
  } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    cp -R "$src" source
    chmod -R u+w source
    testSource="$PWD/source"
    mkdir -p "$testSource/node_modules/solid-js" "$testSource/node_modules/csstype"
    tar -xzf ${solidJS} --strip-components=1 -C "$testSource/node_modules/solid-js"
    tar -xzf ${cssTypes} --strip-components=1 -C "$testSource/node_modules/csstype"
    node --conditions=browser --experimental-strip-types --input-type=module -e "await import('file://$testSource/opencode/terminal/config/terminal-plugin/tui.ts')"
    tsc --project "$testSource/opencode/terminal/tests/opencode-terminal.tsconfig.json" --typeRoots ${nodeTypes}
    node --conditions=browser --test "$testSource/opencode/terminal/tests/opencode-terminal.test.mts" "$testSource/opencode/terminal/tests/tmux-terminal.test.mts"
    touch "$out"
  ''
