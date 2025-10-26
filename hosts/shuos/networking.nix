{hostname, ...}: {
  networking.hostName = hostname;
  networking.networkmanager.enable = true;

  services.tailscale.enable = true;
}
