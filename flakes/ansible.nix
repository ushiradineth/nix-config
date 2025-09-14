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
            pkgs.ansible_2_18
            pkgs.sshpass
            pkgs.python311

            pkgs.ansible-lint
            pkgs.ansible-language-server
            pkgs.vimPlugins.nvim-treesitter-parsers.yaml
          ];
        };
      }
    );
}
