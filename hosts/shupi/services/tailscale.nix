{
  config,
  pkgs,
  mysecrets,
  hostname,
  ...
}: {
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  age.secrets.tailscale-authkey.file = "${mysecrets}/${hostname}/tailscale-authkey.age";

  # Automatic connection and exit node advertisement on boot
  # https://tailscale.com/kb/1096/nixos-minecraft
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale with exit node";
    after = ["network-pre.target" "tailscale.service"];
    wants = ["network-pre.target" "tailscale.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig.Type = "oneshot";

    script = ''
      # Wait for tailscaled to be ready
      sleep 2

      # Check if already authenticated
      status="$(${pkgs.tailscale}/bin/tailscale status -json | ${pkgs.jq}/bin/jq -r .BackendState)"

      if [ "$status" = "Running" ]; then
        echo "Already authenticated to Tailscale"
        exit 0
      fi

      # Authenticate with authkey and advertise as exit node
      ${pkgs.tailscale}/bin/tailscale up \
        --authkey=file:${config.age.secrets.tailscale-authkey.path} \
        --advertise-exit-node \
        --ssh \
        --accept-routes
    '';
  };

  environment.systemPackages = [pkgs.jq];
}
