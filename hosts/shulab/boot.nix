{
  pkgs,
  config,
  lib,
  ...
}: {
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_1;
  boot.initrd.availableKernelModules = lib.mkForce ["xhci_pci" "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "sr_mod" "rtsx_pci_sdmmc"];
  boot.initrd.kernelModules = lib.mkForce ["i915"];
  boot.kernelModules = lib.mkForce ["kvm-intel" "wl"];
  boot.extraModulePackages = lib.mkForce [config.boot.kernelPackages.broadcom_sta];
}
