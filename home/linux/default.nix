{myvars, ...}: {
  home.homeDirectory = "/home/${myvars.username}";
  imports = [
    ../base/core
    ../base/home.nix
  ];
}
