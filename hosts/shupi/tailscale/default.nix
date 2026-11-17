{
  pkgs,
  lib,
  mysecrets,
  hostname,
  config,
  ...
}: {
  age.secrets.tailscale-authkey.file = "${mysecrets}/${hostname}/tailscale-authkey.age";

  environment.systemPackages = [pkgs.jq pkgs.ethtool];

  services.tailscale = {
    enable = true;
    openFirewall = true;
    authKeyFile = config.age.secrets.tailscale-authkey.path;
    authKeyParameters.preauthorized = true;
    useRoutingFeatures = "both";
    disableUpstreamLogging = true;
    extraUpFlags = [
      "--advertise-exit-node"
      "--ssh"
      "--accept-routes"
      "--accept-dns=false" # AdGuard owns DNS in both VPN and direct modes.
    ];
  };

  # Disable UDP GRO forwarding to avoid packet fragmentation
  services.networkd-dispatcher = {
    enable = true;
    rules."50-tailscale-optimizations" = {
      onState = ["routable"];
      script = ''
        ${pkgs.ethtool}/bin/ethtool -K end0 rx-udp-gro-forwarding on rx-gro-list off
      '';
    };
  };

  networking.nftables.enable = true;
  networking.firewall = {
    checkReversePath = lib.mkForce false; # Exit-node traffic to local services needs strict bypass
    trustedInterfaces = ["tailscale0"];
    allowedUDPPorts = [config.services.tailscale.port];
  };

  # Force tailscaled to use nftables (Critical for clean nftables-only systems)
  # This avoids the "iptables-compat" translation layer issues.
  systemd.services.tailscaled.serviceConfig.Environment = [
    "TS_DEBUG_FIREWALL_MODE=nftables"
  ];

  # Optimization: Prevent systemd from waiting for network online
  # Recommended for faster boot with VPNs
  systemd.network.wait-online.enable = false;
  boot.initrd.systemd.network.wait-online.enable = false;
}
