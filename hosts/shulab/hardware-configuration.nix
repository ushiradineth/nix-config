{config, ...}: {
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    # Use Open Source drivers (not supported by 820M)
    open = false;

    nvidiaSettings = false;

    package = config.boot.kernelPackages.nvidiaPackages.legacy_390;

    prime = {
      sync.enable = true;
      nvidiaBusId = "PCI:3:0:0";
      intelBusId = "PCI:0:2:0";
    };
  };

  # Due to legacy nvidia drivers
  nixpkgs.config.allowBroken = true;
  nixpkgs.config.nvidia.acceptLicense = true;
}
