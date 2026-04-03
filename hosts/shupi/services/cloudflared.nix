{
  config,
  hostname,
  mysecrets,
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

  systemd.services."cloudflared-tunnel-shupi".environment = {
    # Avoid tunnel startup failures when local DNS (127.0.0.1) is temporarily unavailable.
    TUNNEL_DNS_RESOLVER_ADDRS = "1.1.1.1:53,1.0.0.1:53";
  };
}
