{pkgs, ...}: {
  programs.zsh.shellInit = ''
    alias tf="terraform";
    alias tfw="terraform workspace";
    alias tfv="terraform validate && terraform fmt --recursive && tflint";
  '';

  environment.systemPackages = with pkgs; [
    awscli2
    eksctl
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
    ])
    (azure-cli.withExtensions [
      azure-cli.extensions.bastion
      azure-cli.extensions.ssh
    ])
    ngrok
    ansible
    terraform
    terraformer # Generate terraform configs from existing cloud resources
    tflint # Terraform linter
    tfsec # Static analysis of terraform code
    tenv # Terraform version manager
    infracost # Terraform cost estimation
  ];
}
