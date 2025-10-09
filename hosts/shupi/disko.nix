{lib, ...}: {
  disko = {
    enableConfig = true;
    rootMountPoint = "/mnt";
    devices.disk.sdCard = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          firmware = {
            label = "FIRMWARE";
            type = "0700";
            start = "1M";
            size = "512M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot/firmware";
              mountOptions = ["fmask=0022" "dmask=0022"];
              extraArgs = ["-F32" "-n" "FIRMWARE"];
            };
          };
          root = {
            label = "NIXOS_SD";
            type = "8300";
            start = "513M";
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = ["noatime"];
              extraArgs = ["-L" "NIXOS_SD"];
            };
          };
        };
      };
    };
  };

  boot.loader.grub.enable = lib.mkForce false;
  fileSystems."/boot/firmware".neededForBoot = true;
}
