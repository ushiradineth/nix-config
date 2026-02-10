_: let
  shellAliases = {
    top = "btop";
    htop = "btop";
  };
in {
  home.shellAliases = shellAliases;
  programs.zsh.shellAliases = shellAliases;

  programs.btop = {
    enable = true;
    settings = {
      color_theme = "Default";
      theme_background = false; # Transparent background
    };
  };
}
