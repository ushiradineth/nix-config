{hostname, ...}: {
  networking.hostName = hostname;
  networking.networkmanager.enable = true;

  networking.nftables.enable = true;

  networking.firewall = {
    allowPing = false;
    enable = true;
    allowedTCPPorts = [22];
    allowedUDPPorts = [];
  };

  # Allow SSH from LAN even when Mullvad kill switch is active.
  networking.firewall.extraInputRules = ''
    ip saddr 192.168.1.0/24 tcp dport 22 accept
  '';
}
