{pkgs, ...}: {
  programs.zsh.shellInit = ''
    alias d="lazydocker"
    alias ld="lazydocker"
  '';

  environment.systemPackages = with pkgs; [
    docker
    lazydocker # Docker TUI
    dive # Explore docker layers
    skopeo # Copy/Sync images between registries and local storage
  ];
}
