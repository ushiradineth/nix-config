{hostname, ...}: {
  networking.hostName = hostname;
  networking.networkmanager = {
    enable = true;
    dns = "none"; # Set nameservers manually
  };

  networking.nameservers = ["127.0.0.1"]; # Use local AdGuard
}
