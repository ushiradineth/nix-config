{
  networking.networkmanager.enable = true;
  networking.firewall.allowPing = false;
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    22 # ssh
    7844 # cloudflared
    8433 # Crafty Dashboard
    25565 # MC Server
    4040 # ngrok Dashboard
    6443 # k3s
  ];
  networking.firewall.allowedUDPPorts = [
    7844 # cloudflared
  ];

  # SSH
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  services.openssh.ports = [22];
}
