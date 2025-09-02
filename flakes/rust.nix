{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = inputs:
    inputs.flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import (inputs.nixpkgs) {inherit system;};
      in {
        devShell = pkgs.mkShell {
          buildInputs =
            pkgs.rustup
            pkgs.libiconv
            pkgs.clang
            pkgs.gcc

            pkgs.rust-analyzer
            pkgs.vimPlugins.nvim-treesitter-parsers.rust
          ];

          RUSTFLAGS = "-l  ${pkgs.libiconv}/lib";
          CC = "clang";
          CXX = "clang++";
        };
      }
    );
}
