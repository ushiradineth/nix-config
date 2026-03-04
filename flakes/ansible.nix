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
  };
}
