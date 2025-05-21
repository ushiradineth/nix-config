{pkgs, ...}: {
  programs.zsh.shellInit = ''
    alias k="kubectl"
    alias x="kubectx"
  '';

  environment.systemPackages = with pkgs; [
    kubectl
    kubectx # Kubernetes context manager
    kubernetes-helm # Helm
    helmfile # Declarative helm deployments
    minikube
    istioctl
    argocd
    kube-score # Kubernetes static analysis
    kube-linter # Kubernetes YAML and Helm linter / Static analysis
  ];
}
