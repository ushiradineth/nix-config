{
  hostname,
  lib,
  ...
}: {
  networking.hostName = hostname;
  networking.networkmanager = {
    enable = true;
    dns = "none"; # Set nameservers manually
  };

  networking.nameservers = ["127.0.0.1"]; # Use local AdGuard

  # Prefer the stable tailnet route over the shared, stale LAN alias on this host only.
  programs.ssh.extraConfig = lib.mkBefore ''
    Host shu
      HostName 100.120.236.115
  '';

  # Ensure containers use AdGuard on the host via docker0 interface
  virtualisation.docker.daemon.settings = {
    dns = ["172.17.0.1"];
  };
}
