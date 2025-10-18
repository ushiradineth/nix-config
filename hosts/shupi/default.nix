{mylib, ...}: {
  imports =
    mylib.scanPaths ./.
    ++ [
      ./services/default.nix
    ];
}
