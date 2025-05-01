{myvars, ...}: {
  home.homeDirectory = "/home/${myvars.username}";
  imports = [
    ../base
  ];
}
