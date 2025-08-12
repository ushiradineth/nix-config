{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    tokei # code statistics
    codex # Terminal based coding agent
    localsend # AirDrop Alternative
    claude-code
    openfortivpn # OpenVPN client compatible with Fortinet VPNs
  ];
}
