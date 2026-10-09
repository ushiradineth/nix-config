{
  config,
  llm-agents,
  managedInstallsEnabled ? false,
  pkgs,
  ...
}: let
  pnpm = import ../../../../lib/pnpm.nix {inherit config pkgs;};
in {
  home.packages = [
    llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode
    pkgs.nodejs
  ];

  home.file = {
    ".cc-safety-net/config.json" = {
      source = ./config/safety-net-config.json;
    };

    ".config/opencode/" = {
      recursive = true;
      source = ./config;
    };
  };

  home.activation = pkgs.lib.optionalAttrs managedInstallsEnabled {
    fallowGlobalInstall = pnpm.mkGlobalInstall {
      packages = ["fallow@3.32.0"];
      stateFile = ".hm-fallow-packages";
      updatePackages = false;
    };
  };
}
