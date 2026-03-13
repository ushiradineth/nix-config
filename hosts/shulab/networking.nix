{hostname, ...}: {
  networking.hostName = hostname;
  networking.networkmanager.enable = true;

  networking.firewall = {
    allowPing = false;
    enable = true;
    allowedTCPPorts = [22];
    allowedUDPPorts = [];
  };
}
