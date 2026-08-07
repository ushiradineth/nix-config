{
  llm-agents,
  pkgs,
  ...
}: {
  home.packages = [
    llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode
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
}
