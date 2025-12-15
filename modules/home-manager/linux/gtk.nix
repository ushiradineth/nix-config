{pkgs, ...}: {
  home.sessionVariables = {
    GTK_USE_PORTAL = "1";
    GTK_THEME = "Adwaita-dark";
    QT_STYLE_OVERRIDE = "adwaita-dark";
  };

  gtk = {
    enable = true;

    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
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
        font-name = "Geist 11";
        gtk-theme = "Adwaita-dark";
        icon-theme = "WhiteSur";
      };
      "org/freedesktop/appearance" = {
        color-scheme = 1; # 1 = prefer dark, 0 = prefer light
      };
    };
  };
}
