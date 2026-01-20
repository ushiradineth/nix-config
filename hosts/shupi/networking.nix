{hostname, ...}: {
  networking.hostName = hostname;
  networking.networkmanager = {
    enable = true;
    dns = "none"; # Set nameservers manually
  };

  networking.nameservers = ["127.0.0.1"]; # Use local AdGuard

  # Ensure containers use AdGuard on the host via docker0 interface
  virtualisation.docker.daemon.settings = {
    dns = ["172.17.0.1"];
  };
}
