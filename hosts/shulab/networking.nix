{}: let
  hostname = "shulab";
in {
  networking.hostName = hostname;
  networking.networkmanager.enable = true;
}
