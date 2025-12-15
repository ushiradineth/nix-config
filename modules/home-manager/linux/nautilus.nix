{pkgs, ...}: {
  home.packages = with pkgs; [
    nautilus
    sushi # spacebar quick preview like macOS
    nautilus-open-any-terminal
  ];

  dconf.settings = {
    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
      show-hidden-files = false;
    };
    "org/gnome/nautilus/list-view" = {
      use-tree-view = true;
    };
    "com/github/stunkymonkey/nautilus-open-any-terminal" = {
      terminal = "ghostty";
    };
  };
}
