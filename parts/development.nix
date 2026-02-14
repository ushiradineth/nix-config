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
    preCommitCheck = inputs.pre-commit-hooks.lib.${system}.run {
      src = ../.;
      hooks = {
        alejandra.enable = true;
        prettier = {
          enable = true;
          settings = {
            write = true;
            configPath = "./.prettierrc.yaml";
          };
        };
        deadnix.enable = true;
        statix.enable = true;
      };
    };
  in {
    checks.pre-commit-check = preCommitCheck;

    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        alejandra.enable = true;
        prettier = {
          enable = true;
          includes = [
            "*.json"
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
        shellcheck.enable = true;
        deadnix.enable = true;
        statix.enable = true;
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
