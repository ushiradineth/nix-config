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
          buildInputs =
            [
              pkgs.erlang_28
              pkgs.elixir_1_18
              pkgs.elixir-ls

              pkgs.vimPlugins.nvim-treesitter-parsers.elixir
            ]
            ++
            # Linux only
            pkgs.lib.optionals pkgs.stdenv.isLinux (
              with pkgs; [
                gigalixir
                inotify-tools
                libnotify
              ]
            )
            ++
            # macOS only
            pkgs.lib.optionals pkgs.stdenv.isDarwin (
              with pkgs; [
                terminal-notifier
              ]
            );
        };
      }
    );
}
