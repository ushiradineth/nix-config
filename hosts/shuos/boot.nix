{pkgs, ...}: {
  # EFI settings
  boot.loader.efi.canTouchEfiVariables = true;

  # Boot menu timeout
  boot.loader.timeout = 10; # 10 seconds timeout

  # Lanzaboote secure boot configuration
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";

    # Configuration limit for secure boot entries
    configurationLimit = 20; # Keep last 20 generations
  };

  environment.systemPackages = with pkgs; [
    sbctl # Secure boot key management
    efibootmgr # EFI boot entry management
  ];
}
