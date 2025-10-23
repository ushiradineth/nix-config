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
}
