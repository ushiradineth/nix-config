{pkgs, ...}: let
  shellAliases = {
    tf = "terraform";
    tfw = "terraform workspace";
    tfv = "terraform validate && terraform fmt --recursive && tflint";
  };
in {
  home.shellAliases = shellAliases;
  programs.zsh.shellAliases = shellAliases;

  home.packages = with pkgs; [
    awscli2
    eksctl
    google-cloud-sdk
    (azure-cli.withExtensions [
      azure-cli.extensions.bastion
      azure-cli.extensions.ssh
    ])
    ngrok
    terraform
    terraformer # Generate terraform configs from existing cloud resources
    tflint
    infracost
    ansible
  ];
}
