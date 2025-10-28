{pkgs, ...}: {
  home.pointerCursor = {
    gtk.enable = false;
    x11.enable = false; # we are on wayland
    package = pkgs.apple-cursor;
    name = "macOS";
    size = 24;
  };

  home.packages = [pkgs.apple-cursor];
}
