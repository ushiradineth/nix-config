{pkgs, ...}: {
  boot.loader = {
    efi.canTouchEfiVariables = true;

    limine = {
      enable = true;
      secureBoot.enable = true;
      maxGenerations = 3;
    };
  };

  environment.systemPackages = with pkgs; [
    sbctl
    efibootmgr
  ];
}
