{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    ghostty
    firefox
    bitwarden
    claude-code
  ];
}
