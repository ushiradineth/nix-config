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
}
