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
            pkgs.lua5_1
            pkgs.luarocks
            pkgs.stylua
            pkgs.lua51Packages.lua-lsp
            pkgs.vimPlugins.nvim-treesitter-parsers.lua
          ];
        };
      }
    );
}
