{
  lib,
  pkgs,
  config,
  managedInstallsEnabled ? false,
  ...
}: let
  pnpm = import ../../../../lib/pnpm.nix {inherit pkgs config;};
in {
  home.activation = lib.mkIf managedInstallsEnabled {
    pnpmGlobalInstall = pnpm.mkGlobalInstall [
      "@anthropic-ai/claude-code"
      "opencode-ai"
      "@openai/codex"
    ];
  };

  home.file = {
    ".cc-safety-net/config.json" = {
      source = ./config/safety-net-config.json;
    };

    ".config/opencode/" = {
      recursive = true;
      source = ./config;
    };
  };
}
