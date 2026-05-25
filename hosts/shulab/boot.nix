{pkgs, ...}: {
  boot.loader = {
    efi.canTouchEfiVariables = true;

    limine = {
      enable = true;
      secureBoot.enable = false;
      maxGenerations = 3;
    };
  };

  environment.systemPackages = with pkgs; [
    sbctl
    efibootmgr
  ];
}
