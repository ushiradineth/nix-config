{
  lib,
  mysecrets,
  hostname,
  config,
  ...
}: {
  age.secrets.tailscale-authkey.file = "${mysecrets}/${hostname}/tailscale-authkey.age";

  services.tailscale = {
    enable = true;
    openFirewall = true;
    authKeyFile = config.age.secrets.tailscale-authkey.path;
    authKeyParameters.preauthorized = true;
    useRoutingFeatures = "both";
    disableUpstreamLogging = true;
    extraUpFlags = [
      "--ssh"
      "--accept-routes"
      "--accept-dns=false"
      "--advertise-tags=tag:shulab"
    ];
  };

  networking.firewall = {
    checkReversePath = lib.mkForce false;
    trustedInterfaces = ["tailscale0"];
    allowedUDPPorts = [config.services.tailscale.port];
  };
}
