{pkgs, ...}: {
  home.sessionVariables = {
    GTK_THEME = "WhiteSur-Dark";
    QT_STYLE_OVERRIDE = "adwaita-dark";
    GTK_USE_PORTAL = "1";
  };
  gtk = {
    enable = true;

    theme = {
      name = "WhiteSur-Dark";
      package = pkgs.whitesur-gtk-theme;
    };

    iconTheme = {
      name = "WhiteSur";
      package = pkgs.whitesur-icon-theme;
    };

    gtk3.extraConfig = {
      gtk-key-theme-name = "Emacs";
      gtk-application-prefer-dark-theme = true;
      gtk-font-name = "Geist 11";
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-font-name = "Geist 11";
    };
  };

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        gtk-key-theme = "Emacs";
        color-scheme = "prefer-dark";
        gtk-theme = "WhiteSur-Dark";
        icon-theme = "WhiteSur";
        font-name = "Geist 11";
      };
      "org/freedesktop/appearance" = {
        color-scheme = 1; # 1 = prefer dark, 0 = prefer light
      };
    };
  };
}
