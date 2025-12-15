{
  pkgs,
  zen-browser,
  ...
}: let
  zen = zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta.meta.desktopFileName;
in {
  xdg = {
    enable = true;
    mime.enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/terminal" = ["com.mitchellh.ghostty.desktop"];

        "application/x-extension-shtml" = [zen];
        "application/x-extension-xhtml" = [zen];
        "application/x-extension-html" = [zen];
        "application/x-extension-xht" = [zen];
        "application/x-extension-htm" = [zen];

        "x-scheme-handler/unknown" = [zen];
        "x-scheme-handler/mailto" = [zen];
        "x-scheme-handler/chrome" = [zen];
        "x-scheme-handler/about" = [zen];
        "x-scheme-handler/https" = [zen];
        "x-scheme-handler/http" = [zen];

        "application/pdf" = [zen];
        "application/xhtml+xml" = [zen];
        "application/json" = [zen];
        "text/plain" = [zen];
        "text/html" = [zen];

        "image/png" = ["imv.desktop"];
        "image/jpeg" = ["imv.desktop"];
        "image/gif" = ["imv.desktop"];
        "image/webp" = ["imv.desktop"];
        "image/bmp" = ["imv.desktop"];
        "image/svg+xml" = ["imv.desktop"];

        "video/mp4" = ["vlc.desktop"];
        "video/x-matroska" = ["vlc.desktop"];
        "video/webm" = ["vlc.desktop"];
        "video/avi" = ["vlc.desktop"];
        "video/quicktime" = ["vlc.desktop"];
        "video/x-msvideo" = ["vlc.desktop"];

        "audio/mpeg" = ["vlc.desktop"];
        "audio/flac" = ["vlc.desktop"];
        "audio/ogg" = ["vlc.desktop"];
        "audio/wav" = ["vlc.desktop"];
        "audio/x-wav" = ["vlc.desktop"];
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
