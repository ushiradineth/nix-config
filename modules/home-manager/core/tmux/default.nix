{
  config,
  pkgs,
  ...
}: let
  quotaHelper = pkgs.writeShellApplication {
    name = "codex-quota";
    runtimeInputs = [pkgs.nodejs];
    text = ''
      if [ -z "''${CODEX_QUOTA_CACHE_DIR:-}" ]; then
        export CODEX_QUOTA_CACHE_DIR=${pkgs.lib.escapeShellArg "${config.xdg.cacheHome}/codex-quota"}
      fi
      exec ${pkgs.nodejs}/bin/node ${./codex-quota.mts} "$@"
    '';
  };
in {
  home.packages = [quotaHelper];

  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";

    extraConfig = builtins.replaceStrings ["codex-quota status"] ["${quotaHelper}/bin/codex-quota status"] (builtins.readFile ./.tmux.conf);
  };
}
