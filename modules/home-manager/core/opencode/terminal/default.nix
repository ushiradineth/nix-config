{
  config,
  pkgs,
  pkgs-unstable,
  ...
}: let
  psPath =
    if pkgs.stdenv.isDarwin
    then "/bin/ps"
    else "${pkgs.procps}/bin/ps";
  terminalHelper = pkgs.writeShellApplication {
    name = "opencode-terminal";
    runtimeInputs = [pkgs.nodejs pkgs.tmux pkgs.fzf] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [pkgs-unstable.terminal-notifier];
    text = ''
      export OPENCODE_TERMINAL_HELPER="$0"
      export OPENCODE_TERMINAL_STATE_DIR=${pkgs.lib.escapeShellArg "${config.xdg.stateHome}/opencode-terminal"}
      export OPENCODE_TERMINAL_TMUX=${pkgs.tmux}/bin/tmux
      export OPENCODE_TERMINAL_PS=${psPath}
      export OPENCODE_TERMINAL_FZF=${pkgs.fzf}/bin/fzf
      ${pkgs.lib.optionalString pkgs.stdenv.isDarwin ''export OPENCODE_TERMINAL_NOTIFIER=${pkgs-unstable.terminal-notifier}/bin/terminal-notifier''}
      exec ${pkgs.nodejs}/bin/node ${./config/terminal/terminal-context.mts} "$@"
    '';
  };
  notifierPolicy = builtins.fromJSON (builtins.readFile ./notifier.json);
  notifierConfig =
    notifierPolicy
    // {
      notification = !pkgs.stdenv.isDarwin;
      command = notifierPolicy.command // {path = "${terminalHelper}/bin/opencode-terminal";};
      events = pkgs.lib.mapAttrs (_name: event: event // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {notification = false;}) notifierPolicy.events;
    };
in {
  home.packages = [terminalHelper];
  home.sessionVariables = {
    OPENCODE_TERMINAL_STATE_DIR = "${config.xdg.stateHome}/opencode-terminal";
    OPENCODE_TERMINAL_TMUX = "${pkgs.tmux}/bin/tmux";
    OPENCODE_TERMINAL_PS = psPath;
  };
  home.file = {
    ".config/opencode/plugins/terminal-context.ts".source = "${./config}/plugins/terminal-context.ts";
    ".config/opencode/terminal/terminal-context.mts".source = "${./config}/terminal/terminal-context.mts";
    ".config/opencode/opencode-notifier.json".text = builtins.toJSON notifierConfig;
  };
}
