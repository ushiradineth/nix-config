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
  };
}
