{...}: let
  hostname = "shuos";
in {
  networking.hostName = hostname;
  networking.networkmanager.enable = true;
}
