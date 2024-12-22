{pkgs, ...}: {
  home.packages = with pkgs; [
    mycli
    pgcli
    mongosh
    devbox
    k6 # Load testing tool
    devcontainer # VSCode's dev container CLI
  ];

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
    };
  };
}
