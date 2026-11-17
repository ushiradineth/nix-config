{
  config,
  llm-agents,
  managedInstallsEnabled ? false,
  pkgs,
  ...
}: let
  pnpm = import ../../../../lib/pnpm.nix {inherit config pkgs;};
in {
  imports = [./assistant ./terminal];

  home.packages = [
    (import ./package.nix {
      inherit pkgs;
      upstream = llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2;
    })
    pkgs.nodejs
  ];

  home.file.".config/opencode/" = {
    recursive = true;
    source = ./config;
  };

  home.activation = pkgs.lib.optionalAttrs managedInstallsEnabled {
    fallowGlobalInstall = pnpm.mkGlobalInstall {
      packages = ["fallow@3.32.0"];
      stateFile = ".hm-fallow-packages";
      updatePackages = false;
    };
  };
}
