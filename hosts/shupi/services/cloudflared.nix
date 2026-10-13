{
  config,
  hostname,
  mysecrets,
  lib,
  ...
}: {
  age.secrets.cloudflare-tunnel-token.file = "${mysecrets}/${hostname}/cloudflare-tunnel-token.age";

  services.cloudflared = {
    enable = true;
    tunnels = {
      "shupi" = {
        credentialsFile = config.age.secrets.cloudflare-tunnel-token.path;
        default = "http_status:404";
      };
    };
  };

  systemd.services."cloudflared-tunnel-shupi" = {
    after = ["mullvad-daemon.service"];
    wants = ["mullvad-daemon.service"];
    partOf = ["mullvad-daemon.service"];

    environment = {
      # Avoid tunnel startup failures when local DNS (127.0.0.1) is temporarily unavailable.
      TUNNEL_DNS_RESOLVER_ADDRS = "1.1.1.1:53,1.0.0.1:53";
      # Split tunneling otherwise retains the VPN source address on the LAN interface.
      TUNNEL_EDGE_BIND_ADDRESS = "192.168.1.13";
    };

    unitConfig = {
      StartLimitIntervalSec = 0;
    };

    serviceConfig = {
      # Exclude each new PID without running cloudflared itself as root.
      ExecStartPost = "+${config.services.mullvad-vpn.package}/bin/mullvad split-tunnel add $MAINPID";
      Restart = lib.mkForce "always";
      RestartSec = "30s";
    };
  };
}
