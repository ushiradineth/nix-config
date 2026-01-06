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
      "--accept-dns=false" # Disabled to avoid conflict with Mullvad's DNS pointed to AdGuard
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

  # Clear Tailscale marks so local services route via tailscale0
  networking.nftables.tables.tailscale-prerouting-mark = {
    family = "ip";
    content = ''
      chain prerouting {
        type filter hook prerouting priority mangle + 10; policy accept;
        iifname "tailscale0" ip saddr 100.64.0.0/10 meta mark set 0x00000000 ct mark set 0x00000000
      }
    '';
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
