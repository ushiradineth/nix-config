{hostname, ...}: {
  networking.hostName = hostname;
  networking.networkmanager.enable = true;

  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;
}
