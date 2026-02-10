{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs:
    inputs.flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import inputs.nixpkgs {inherit system;};
      in {
        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.go_1_25

            pkgs.gopls
            pkgs.gofumpt
            pkgs.goimports-reviser
            pkgs.golines
            pkgs.golangci-lint
            pkgs.air
            pkgs.govulncheck

            pkgs.vimPlugins.nvim-treesitter-parsers.go
            pkgs.vimPlugins.nvim-treesitter-parsers.gomod
          ];
        };
      }
    );
}
