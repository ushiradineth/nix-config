{myvars, ...}: {
  home.homeDirectory = "/home/${myvars.username}";
  imports = [
    ../base/core
    ../base/tui
    ../base/home.nix
  ];
}
