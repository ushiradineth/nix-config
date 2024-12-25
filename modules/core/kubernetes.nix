{pkgs, ...}: {
  programs.zsh.shellInit = ''
    alias k="kubectl"
  '';

  environment.systemPackages = with pkgs; [
    kubectl
    kubectx
    kubernetes-helm
    helmfile
    minikube
  ];
}
