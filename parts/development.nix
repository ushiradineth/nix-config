{inputs, ...}: {
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem = {
    config,
    pkgs,
    system,
    ...
  }: let
    terminalTypes = import ../lib/opencode-terminal-types.nix {inherit pkgs;};
    terminalTestProcess = pkgs.writeShellScript "opencode-terminal-test-process" ''
      printf 'test-process-%s\n' "$2"
    '';
    preCommitCheck = inputs.pre-commit-hooks.lib.${system}.run {
      src = ../.;
      hooks = {
        alejandra.enable = true;
        prettier = {
          enable = true;
          package = pkgs.prettier;
          settings = {
            write = true;
            configPath = "./.prettierrc.yaml";
          };
        };
        deadnix.enable = true;
        statix.enable = true;
        typos = {
          enable = true;
          settings = {
            configPath = "./.typos.toml";
            write = true;
          };
        };
      };
    };
  in {
    checks.pre-commit-check = preCommitCheck;
    checks.opencode-terminal =
      pkgs.runCommand "opencode-terminal-tests" {
        src = ../.;
        nativeBuildInputs = [pkgs.nodejs pkgs.tmux pkgs.typescript] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [pkgs.procps];
        OPENCODE_TERMINAL_PS =
          if pkgs.stdenv.isDarwin
          then "${terminalTestProcess}"
          else "${pkgs.procps}/bin/ps";
      } ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        tsc --project "$src/tests/opencode-terminal.tsconfig.json" --typeRoots ${terminalTypes}
        node --test "$src/tests/opencode-terminal.test.mts" "$src/tests/tmux-terminal.test.mts"
        touch "$out"
      '';

    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        alejandra.enable = true;
        prettier = {
          enable = true;
          package = pkgs.prettier;
          includes = [
            "*.json"
            "*.js"
            "*.mjs"
            "*.ts"
            "*.mts"
            "*.md"
            "*.yaml"
            "*.yml"
            "*.css"
          ];
          excludes = [
            "flake.lock"
          ];
        };
        shfmt = {
          enable = true;
          indent_size = 2;
        };
        shellcheck = {
          enable = true;
          excludes = [
            ".envrc"
          ];
        };
        deadnix.enable = true;
        statix.enable = true;
        typos = {
          enable = true;
          configFile = ".typos.toml";
        };
      };
    };

    formatter = config.treefmt.build.wrapper;

    devShells.default = pkgs.mkShell {
      name = "nix-config-devshell";
      packages = with pkgs; [
        deadnix
        statix
        nil
        nixos-rebuild
        home-manager
        git
        jq
        convco
        config.treefmt.build.wrapper
      ];
      NIX_CONFIG = "experimental-features = nix-command flakes";
      inherit (preCommitCheck) shellHook;
    };
  };
}
