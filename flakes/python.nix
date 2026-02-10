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
            pkgs.python313
            pkgs.python313Packages.autopep8
            pkgs.python313Packages.python-lsp-server
            pkgs.vimPlugins.nvim-treesitter-parsers.python
          ];
        };
      }
    );
}
