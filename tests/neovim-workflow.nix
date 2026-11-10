{
  pkgs,
  nixvim,
}: let
  # Instrument executables, not Conform's selection or save callbacks.
  logged = name: package:
    pkgs.writeShellScriptBin name ''
      printf '%s\n' '${name}' >> "$FORMATTER_LOG"
      exec ${pkgs.lib.getExe package} "$@"
    '';
  prettier = logged "prettier" pkgs.prettier;
  biome = logged "biome" pkgs.biome;
  testPkgs = pkgs // {inherit prettier biome;};
  production = ../modules/home-manager/core/neovim;
  editor = nixvim.legacyPackages.${pkgs.stdenv.hostPlatform.system}.makeNixvim {
    nixpkgs.pkgs = pkgs;
    imports =
      map
      (path:
        (import path {
          pkgs = testPkgs;
          inherit (pkgs) lib;
        }).programs.nixvim)
      [
        (production + /keymaps.nix)
        (production + /options.nix)
        (production + /autocmd.nix)
        (production + /plugins/conform.nix)
        (production + /plugins/git.nix)
        (production + /plugins/telescope.nix)
      ];
    extraPackages = [biome prettier pkgs.git];
  };
in
  pkgs.runCommand "neovim-workflow" {nativeBuildInputs = [editor pkgs.git];} ''
    export HOME="$TMPDIR/home"
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_DATA_HOME="$HOME/.local/share"
    export XDG_STATE_HOME="$HOME/.local/state"
    export XDG_CACHE_HOME="$HOME/.cache"
    export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
    export FORMATTER_LOG="$TMPDIR/formatters.log"
    export LC_ALL=C.UTF-8
    mkdir -p "$HOME"
    touch "$FORMATTER_LOG"
    nvim --headless -i NONE -n -c "lua vim.schedule(function() local ok, err = pcall(dofile, '${./neovim-workflow.lua}'); if not ok then print(err); vim.cmd('cquit 1') end end)"
    touch "$out"
  ''
