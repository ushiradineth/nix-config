{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    ghostty
    discord
    bitwarden
    claude-code
    seafile-client
    localsend # AirDrop alternative
    expect # Automate interactive applications
    figma-linux
    notion-app-enhanced
    dust # Disk usage analyzer
    procs # Modern process viewer
    seafile-client
  ];
}
