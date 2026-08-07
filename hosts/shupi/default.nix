{mylib, ...}: {
  imports =
    mylib.scanPaths ./.
    ++ [
      ./services/default.nix
    ];

  system.stateVersion = "25.11";
}
