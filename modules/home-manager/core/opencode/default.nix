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
    pnpmGlobalInstall = pnpm.mkGlobalInstall {
      packages = [
        "opencode-ai"
      ];

      postinstallPackages = ["opencode-ai"];
    };
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
