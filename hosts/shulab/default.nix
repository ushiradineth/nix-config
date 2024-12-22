{mylib, ...}: let
  hostname = "shulab";
in {
  networking.hostName = hostname;
  networking.computerName = hostname;
  system.defaults.smb.NetBIOSName = hostname;

  imports = mylib.scanPaths ./.;
}
