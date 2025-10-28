{...}: {
  xdg = {
    enable = true;
    mime.enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = {
        # Set Ghostty as default terminal
        "x-scheme-handler/terminal" = ["com.mitchellh.ghostty.desktop"];

        # Set Zen as default browser
        "text/html" = ["zen.desktop"];
        "x-scheme-handler/http" = ["zen.desktop"];
        "x-scheme-handler/https" = ["zen.desktop"];
        "x-scheme-handler/about" = ["zen.desktop"];
        "x-scheme-handler/unknown" = ["zen.desktop"];

        # Additional common MIME types
        "application/pdf" = ["zen.desktop"];
        "image/png" = ["imv.desktop"];
        "image/jpeg" = ["imv.desktop"];
        "image/gif" = ["imv.desktop"];
        "video/mp4" = ["mpv.desktop"];
        "audio/mpeg" = ["mpv.desktop"];
      };
    };
    portal = {
      enable = true;
      xdgOpenUsePortal = true;
      config = {
        common = {
          default = ["gtk"];
        };
        hyprland = {
          default = ["hyprland" "gtk"];
        };
      };
    };
    userDirs = {
      enable = true;
      createDirectories = true;
      documents = "$HOME/Documents";
      download = "$HOME/Downloads";
      videos = "$HOME/Videos";
      music = "$HOME/Music";
      pictures = "$HOME/Pictures";
      desktop = "$HOME/Desktop";
      publicShare = "$HOME/Public";
      templates = "$HOME/Templates";
    };
  };

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # For Electron apps to use Wayland
  };
}
