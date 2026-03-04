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
            pkgs.go_1_25

            pkgs.gopls
            pkgs.gofumpt
            pkgs.goimports-reviser
            pkgs.golines
            pkgs.golangci-lint
            pkgs.air
            pkgs.govulncheck

            pkgs.vimPlugins.nvim-treesitter-parsers.go
            pkgs.vimPlugins.nvim-treesitter-parsers.gomod
          ];
        };
      }
    );
  };
}
