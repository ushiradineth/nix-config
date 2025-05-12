{...}: {
  fileSystems."/" = {
    device = "/dev/vdb1";
    fsType = "btrfs";
    options = ["subvol=/scon/containers/01JTAPTT3EPVTB51YHEM71CZM1/rootfs"];
  };

  boot.loader.grub.devices = ["/dev/vdb"];
}
