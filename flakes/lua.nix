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
  in
    nixpkgs.lib.genAttrs systems (
      system: let
        pkgs = import nixpkgs {inherit system;};
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
