{
  networking.firewall.allowPing = false;
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    22 # ssh
    7844 # cloudflared
    8433 # Crafty Dashboard
    25565 # MC Server
    4040 # ngrok Dashboard
  ];
  networking.firewall.allowedUDPPorts = [
    7844 # cloudflared
  ];
}
