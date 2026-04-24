{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    ghostty
    bitwarden-desktop
    seafile-client
    localsend # AirDrop alternative
    figma-linux
    obsidian
    obs-studio
    vesktop # Discord client
    burpsuite
    vlc
  ];
}
