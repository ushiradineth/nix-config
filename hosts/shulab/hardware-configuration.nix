{
  config,
  lib,
}: {
  boot.initrd.availableKernelModules = lib.mkForce ["xhci_pci" "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "sr_mod" "rtsx_pci_sdmmc"];
  boot.initrd.kernelModules = lib.mkForce ["i915"];
  boot.kernelModules = lib.mkForce ["kvm-intel" "wl"];
  boot.extraModulePackages = lib.mkForce [config.boot.kernelPackages.broadcom_sta];
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
