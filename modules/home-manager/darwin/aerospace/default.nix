{config, ...}: {
  xdg.configFile."../.aerospace.toml".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/modules/home-manager/darwin/aerospace/aerospace.toml";
}
