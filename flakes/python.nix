{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  in {
    devShells = nixpkgs.lib.genAttrs systems (
      system: let
        pkgs = import nixpkgs {inherit system;};
      in {
        default = pkgs.mkShell {
          buildInputs = [
            pkgs.python313
            pkgs.python313Packages.autopep8
            pkgs.python313Packages.python-lsp-server
            pkgs.vimPlugins.nvim-treesitter-parsers.python
          ];
        };
      }
    );
  };
}
