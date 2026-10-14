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
    quotaModule = import ../modules/home-manager/core/tmux {
      inherit pkgs;
      myvars = import ../vars {};
      config.xdg.cacheHome = "/unused-quota-test-cache";
      config.home.homeDirectory = "/unused-navigation-test-home";
    };
    quotaHelper = builtins.head quotaModule.home.packages;
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
    checks.tmux-navigation =
      pkgs.runCommand "tmux-navigation-tests" {
        src = ../.;
        nativeBuildInputs = [pkgs.nodejs pkgs.tmux pkgs.fzf pkgs.typescript];
        TMUX_NAVIGATION_TEST_SHELL = pkgs.runtimeShell;
      } ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        tsc --project "$src/tests/tmux-navigation.tsconfig.json" --typeRoots ${terminalTypes}
        node --test "$src/tests/tmux-navigation.test.mts"
        touch "$out"
      '';
    checks.python-tests =
      pkgs.runCommand "python-tests" {
        src = ../.;
        nativeBuildInputs = [pkgs.python3];
      } ''
        export HOME="$TMPDIR/home"
        export PYTHONDONTWRITEBYTECODE=1
        mkdir -p "$HOME"
        cp -R "$src" source
        chmod -R u+w source
        cd source
        # Git snapshots omit the manifest's two excluded empty placeholders.
        mkdir -p modules/home-manager/core/opencode/config/skills/{dispatching-parallel-agents,impeccable-style}
        python3 tests/status-digest-test.py
        python3 tests/agent-browser-task-test.py
        python3 tests/agent-capabilities-test.py
        python3 tests/i-have-adhd-test.py
        touch "$out"
      '';
    checks.security-audit-validators =
      pkgs.runCommand "security-audit-validator-tests" {
        src = ../modules/home-manager/core/opencode/config/skills/security-audit;
        nativeBuildInputs = [pkgs.nodejs];
      } ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        node --test "$src/validate-findings.test.cjs" "$src/validate-coverage-ledger.test.cjs"
        touch "$out"
      '';
    checks.codex-quota =
      pkgs.runCommand "codex-quota-tests" {
        src = ../.;
        nativeBuildInputs = [pkgs.nodejs pkgs.tmux pkgs.typescript];
        CODEX_QUOTA_TEST_HELPER = "${quotaHelper}/bin/codex-quota";
        CODEX_QUOTA_TEST_CONFIG = pkgs.writeText "quota-tmux.conf" quotaModule.programs.tmux.extraConfig;
      } ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        tsc --project "$src/tests/codex-quota.tsconfig.json" --typeRoots ${terminalTypes}
        node --test "$src/tests/codex-quota.test.mts"
        touch "$out"
      '';
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
