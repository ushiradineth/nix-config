{
  config,
  pkgs,
  ...
}: let
  globalConfig = "${config.xdg.configHome}/typos/typos.toml";
  shellAliases.typos = "typos --config ${globalConfig}";
in {
  home = {
    packages = [pkgs.typos];
    inherit shellAliases;
  };

  programs.zsh.shellAliases = shellAliases;

  xdg.configFile."typos/typos.toml".source = ./typos.toml;

  programs.nixvim.plugins.lsp.servers.typos_lsp = {
    enable = true;
    extraOptions.init_options = {
      config = globalConfig;
      diagnosticSeverity = "Hint";
    };
  };
}
