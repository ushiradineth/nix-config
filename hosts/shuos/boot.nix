{pkgs, ...}: {
  boot.loader = {
    efi.canTouchEfiVariables = true;
    timeout = 10; # 10 seconds timeout

    limine = {
      enable = true;
      secureBoot.enable = true;
      maxGenerations = 3;
      extraEntries = ''
        /Windows 11
          protocol: efi
          path: guid(d9e4cf96-114d-4c5c-9720-b55e696e01b0):/EFI/Microsoft/Boot/bootmgfw.efi
      '';
      style = {
        interface = {
          resolution = "1920x1080";
          helpHidden = true;
          branding = "shuos";
          brandingColor = 7; # gray
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [
    sbctl # Secure boot key management
    efibootmgr # EFI boot entry management
  ];
}
