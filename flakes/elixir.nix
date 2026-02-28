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
