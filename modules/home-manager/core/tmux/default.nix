{
  config,
  pkgs,
  ...
}: let
  commandAliases = {
    ".opencode-wrapp" = "oc";
    ".opencode-wrapped" = "oc";
    opencode = "oc";
    lazygit = "lg";
  };
  attentionBadge = {
    label = "OC";
    color = "#FF95B5";
  };
  validAliases = builtins.all (name:
    builtins.match "[A-Za-z0-9_.-]+" name
    != null
    && builtins.match "[A-Za-z0-9_.-]+" commandAliases.${name} != null) (builtins.attrNames commandAliases);
  aliasFormat = assert validAliases;
    builtins.foldl'
    (fallback: name: "#{?#{==:#{pane_current_command},${name}},${commandAliases.${name}},${fallback}}")
    "#{pane_current_command}" (builtins.attrNames commandAliases);
  renameFormat = "#{?pane_in_mode,[tmux],${aliasFormat}}#{?pane_dead,[dead],}";
  badgeStyle = assert builtins.match "#[A-Fa-f0-9]{6}" attentionBadge.color
  != null
  && builtins.match "[A-Za-z0-9_-]+" attentionBadge.label != null; "#[fg=#${attentionBadge.color}#,bold]${attentionBadge.label}:";
  navigationSettings = pkgs.writeText "tmux-navigation.json" (builtins.toJSON {
    home = config.home.homeDirectory;
    manualPaths = map (path: "${config.home.homeDirectory}/${path}") ["nix-config" "nix-secrets" ".config"];
    roots = map (root: root // {path = "${config.home.homeDirectory}/${root.path}";}) [
      {
        path = "Code";
        minDepth = 1;
        maxDepth = 1;
      }
      {
        path = "Code/surge";
        minDepth = 1;
        maxDepth = 2;
      }
      {
        path = "Code/fork";
        minDepth = 1;
        maxDepth = 1;
      }
      {
        path = "Code/koano";
        minDepth = 1;
        maxDepth = 1;
      }
      {
        path = "Code/freelance";
        minDepth = 1;
        maxDepth = 1;
      }
    ];
  });
  navigationHelper = pkgs.writeShellApplication {
    name = "tmux-navigation";
    runtimeInputs = [pkgs.nodejs pkgs.tmux pkgs.fzf];
    text = ''
      export TMUX_NAVIGATION_SETTINGS=${navigationSettings}
      export TMUX_NAVIGATION_TMUX=${pkgs.tmux}/bin/tmux
      export TMUX_NAVIGATION_FZF=${pkgs.fzf}/bin/fzf
      export TMUX_NAVIGATION_HELPER="$0"
      exec ${pkgs.nodejs}/bin/node ${./navigation.mts} "$@"
    '';
  };
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
  home.packages = [quotaHelper navigationHelper];

  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";

    extraConfig =
      builtins.replaceStrings
      ["codex-quota status" "tmux-navigation sessions" "tmux-navigation projects" "#[fg=##FF95B5#,bold]OC:"]
      ["${quotaHelper}/bin/codex-quota status" "${navigationHelper}/bin/tmux-navigation sessions" "${navigationHelper}/bin/tmux-navigation projects" badgeStyle]
      (builtins.readFile ./.tmux.conf)
      + ''
        set-window-option -g automatic-rename-format '${renameFormat}'
      '';
  };
}
