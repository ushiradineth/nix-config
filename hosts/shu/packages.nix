{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    localsend # AirDrop Alternative
    openfortivpn # OpenVPN client compatible with Fortinet VPNs
  ];
}
