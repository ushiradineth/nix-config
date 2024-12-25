{myvars, ...}: {
  home.homeDirectory = "/home/${myvars.username}";
  imports = [
    ../base/core
    ../base/tui/devtools.nix
    ../base/home.nix
  ];
}
