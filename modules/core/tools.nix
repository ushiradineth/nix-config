{pkgs, ...}: {
  home.packages = with pkgs; [
    pgcli
    mycli
    k6 # Load testing tool
    vegeta # Load testing tool
    wireshark # Network protocol analyzer
  ];

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
    };
  };
}
