{
  config,
  llm-agents,
  managedInstallsEnabled ? false,
  pkgs,
  ...
}: let
  pnpm = import ../../../../lib/pnpm.nix {inherit config pkgs;};
  loopHelper = import ../../../../lib/oc-loop.nix {
    inherit pkgs;
    opencode = llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
  };
  psPath =
    if pkgs.stdenv.isDarwin
    then "/bin/ps"
    else "${pkgs.procps}/bin/ps";
  terminalHelper = pkgs.writeShellApplication {
    name = "opencode-terminal";
    runtimeInputs = [pkgs.nodejs pkgs.tmux pkgs.fzf] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [pkgs.terminal-notifier];
    text = ''
      export OPENCODE_TERMINAL_HELPER="$0"
      export OPENCODE_TERMINAL_STATE_DIR=${pkgs.lib.escapeShellArg "${config.xdg.stateHome}/opencode-terminal"}
      export OPENCODE_TERMINAL_TMUX=${pkgs.tmux}/bin/tmux
      export OPENCODE_TERMINAL_PS=${psPath}
      export OPENCODE_TERMINAL_FZF=${pkgs.fzf}/bin/fzf
      ${pkgs.lib.optionalString pkgs.stdenv.isDarwin ''export OPENCODE_TERMINAL_NOTIFIER=${pkgs.terminal-notifier}/bin/terminal-notifier''}
      exec ${pkgs.nodejs}/bin/node ${./config/terminal/terminal-context.mts} "$@"
    '';
  };
  notifierPolicy = builtins.fromJSON (builtins.readFile ./config/opencode-notifier.json);
  notifierConfig =
    notifierPolicy
    // {
      notification = !pkgs.stdenv.isDarwin;
      command = notifierPolicy.command // {path = "${terminalHelper}/bin/opencode-terminal";};
      events = pkgs.lib.mapAttrs (_name: event: event // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {notification = false;}) notifierPolicy.events;
    };
in {
  home.packages = [
    llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode
    pkgs.nodejs
    terminalHelper
    loopHelper
  ];

  home.sessionVariables = {
    OPENCODE_TERMINAL_STATE_DIR = "${config.xdg.stateHome}/opencode-terminal";
    OPENCODE_TERMINAL_TMUX = "${pkgs.tmux}/bin/tmux";
    OPENCODE_TERMINAL_PS = psPath;
  };

  home.file = {
    ".cc-safety-net/config.json" = {
      source = ./config/safety-net-config.json;
    };

    ".config/opencode/" = {
      recursive = true;
      source = pkgs.lib.cleanSourceWith {
        src = ./config;
        filter = path: _type: path != "${toString ./config}/opencode-notifier.json";
      };
    };

    ".config/opencode/opencode-notifier.json".text = builtins.toJSON notifierConfig;
  };

  home.activation = pkgs.lib.optionalAttrs managedInstallsEnabled {
    fallowGlobalInstall = pnpm.mkGlobalInstall {
      packages = ["fallow@3.32.0"];
      stateFile = ".hm-fallow-packages";
      updatePackages = false;
    };
  };
}
