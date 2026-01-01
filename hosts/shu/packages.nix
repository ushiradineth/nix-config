{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    localsend # AirDrop Alternative
    openfortivpn # OpenVPN client compatible with Fortinet VPNs
    restic # Backup tool for macOS code backup
    websocat # WebSocket client
  ];
}
