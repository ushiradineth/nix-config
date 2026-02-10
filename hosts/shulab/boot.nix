{
  pkgs,
  lib,
  ...
}: {
  boot = {
    loader.grub = {
      enable = true;
      device = "/dev/sda";
    };
    kernelPackages = lib.mkForce pkgs.linuxPackages_6_1;
  };
}
