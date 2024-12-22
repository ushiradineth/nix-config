{mylib, ...}: let
  hostname = "shulab";
in {
  networking.hostName = hostname;
  imports = mylib.scanPaths ./.;
}
