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
    azure-cli
    ngrok
    terraform
    terraformer # Generate terraform configs from existing cloud resources
    tflint
    infracost
    ansible
  ];
}
