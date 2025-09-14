{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs:
    inputs.flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import (inputs.nixpkgs) {inherit system;};
      in {
        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.php84
            pkgs.pretty-php
            pkgs.intelephense
            pkgs.vimPlugins.nvim-treesitter-parsers.php
          ];
        };
      }
    );
}
