{pkgs, ...}: let
  shellAliases = {
    k = "kubectl";
    d = "lazydocker";
    ld = "lazydocker";
  };
in {
  home.shellAliases = shellAliases;
  programs.zsh.shellAliases = shellAliases;

  home.packages = with pkgs; [
    kubectl
    kubectx
    kubernetes-helm
    kind
    minikube
    istioctl
    dive # Explore docker layers
    lazydocker # Docker TUI
    skopeo # Copy/Sync images between registries and local storage
  ];
}
