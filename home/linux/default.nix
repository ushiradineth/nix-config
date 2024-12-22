{
  mylib,
  myvars,
  ...
}: {
  home.homeDirectory = "/home/${myvars.username}";
  imports =
    (mylib.scanPaths ./.)
    ++ [
      ../base/core
      ../base/tui
      ../base/home.nix
    ];
}
