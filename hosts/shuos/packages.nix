{
  pkgs,
  pkgs-unstable,
  ...
}: {
  environment.systemPackages = with pkgs; [
    ghostty
    pkgs-unstable.bitwarden-desktop
    seafile-client
    localsend # AirDrop alternative
    figma-linux
    obs-studio
    vesktop # Discord client
    burpsuite
    vlc
  ];
}
