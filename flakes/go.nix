{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = inputs:
    inputs.flake-utils.lib.eachdefaultsystem (
      system: let
        pkgs = import (inputs.nixpkgs) {inherit system;};
      in {
        devshell = pkgs.mkshell {
          buildInputs = [
            pkgs.go_1_24

            pkgs.gopls
            pkgs.gofumpt
            pkgs.goimp
            pkgs.golines

            pkgs.vimPlugins.nvim-treesitter-parsers.go
            pkgs.vimPlugins.nvim-treesitter-parsers.gomod
          ];
        };
      }
    );
}
