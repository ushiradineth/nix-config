{pkgs, ...}: {
  programs.zsh.shellInit = ''
    alias k="kubectl"
    alias x="kubectx"
  '';

  environment.systemPackages = with pkgs; [
    kubectl
    kubectx
    kubernetes-helm
    helmfile
    minikube
    istioctl
    argocd
    kube-score
    kube-linter
  ];
}
