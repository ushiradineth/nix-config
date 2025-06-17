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
            pkgs.kubernetes-helm
            pkgs.helm-ls
            pkgs.helm-dashboard
            pkgs.yamllint
            pkgs.yaml-language-server
            pkgs.vimPlugins.nvim-treesitter-parsers.helm
            pkgs.vimPlugins.nvim-treesitter-parsers.gotmpl
            pkgs.vimPlugins.nvim-treesitter-parsers.yaml
          ];
        };
      }
    );
}
