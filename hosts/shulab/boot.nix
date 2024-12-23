{
  pkgs,
  lib,
  ...
}: {
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_1;
}
