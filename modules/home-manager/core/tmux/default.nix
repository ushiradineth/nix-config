{config, ...}: {
  xdg.configFile."../.tmux.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/modules/home-manager/core/tmux/.tmux.conf";
  programs.tmux.enable = true;
}
