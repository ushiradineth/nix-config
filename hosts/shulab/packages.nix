{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    pciutils # lspci
    usbutils # lsusb
    lshw # lscpu
    parted
    wezterm # terminal emulator (access through ssh)
  ];
}
