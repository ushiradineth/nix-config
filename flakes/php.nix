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
          buildinputs = [
            pkgs.php84
            pkgs.php84Packages.php-cs-fixer
            pkgs.intelephense
            pkgs.vimPlugins.nvim-treesitter-parsers.php
          ];
        };
      }
    );
}
