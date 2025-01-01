{pkgs, ...}: {
  home.packages = with pkgs; [
    pgcli
    mycli
    k6 # Load testing tool
    vegeta # Load testing tool
  ];

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
    };
  };
}
