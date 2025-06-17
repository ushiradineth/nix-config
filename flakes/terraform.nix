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
            pkgs.terraform
            pkgs.tenv

            pkgs.tfsec
            pkgs.tflint
            pkgs.hclfmt

            pkgs.terraform-ls
            pkgs.vimPlugins.nvim-treesitter-parsers.terraform
          ];
        };
      }
    );
}
