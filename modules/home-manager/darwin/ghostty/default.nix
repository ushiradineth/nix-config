{config, ...}: {
  xdg.configFile."ghostty/config".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/modules/home-manager/darwin/ghostty/config";
}
