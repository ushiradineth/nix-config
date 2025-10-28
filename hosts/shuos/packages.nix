{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    ghostty
    discord
    bitwarden
    claude-code
    opencloud-desktop
    localsend # AirDrop alternative
    expect # Automate interactive applications
    figma-linux
    notion-app-enhanced
    dust # Disk usage analyzer
    procs # Modern process viewer
  ];
}
