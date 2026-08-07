{mylib, ...}: {
  imports = mylib.scanPaths ./.;

  system.stateVersion = "25.11";
}
