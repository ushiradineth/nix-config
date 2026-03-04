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
            pkgs.nodejs
            pkgs.pnpm
            # pkgs.yarn

            pkgs.nodePackages.typescript-language-server
            pkgs.vimPlugins.nvim-treesitter-parsers.typescript
            pkgs.tailwindcss-language-server
            pkgs.vimPlugins.tailwindcss-colors-nvim

            pkgs.biome

            # pkgs.eslint_d
            # pkgs.prettierd
            # pkgs.astro-language-server
            # pkgs.vue-language-server
          ];
        };
      }
    );
  };
}
