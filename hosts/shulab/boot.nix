{
  pkgs,
  config,
  ...
}: {
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.kernelPackages = pkgs.linuxPackages_6_1;
  boot.initrd.availableKernelModules = ["xhci_pci" "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "sr_mod" "rtsx_pci_sdmmc"];
  boot.initrd.kernelModules = ["i915"];
  boot.kernelModules = ["kvm-intel" "wl"];
  boot.extraModulePackages = [config.boot.kernelPackages.broadcom_sta];
}
