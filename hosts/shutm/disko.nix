{lib, ...}: {
  disko = {
    enableConfig = true;
    rootMountPoint = "/mnt";
    devices.disk.main = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            type = "ef00";
            label = "BOOT";
            start = "1M";
            size = "512M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot/efi";
              mountOptions = ["fmask=0022" "dmask=0022"];
              extraArgs = ["-n" "BOOT"];
            };
          };
          root = {
            type = "8300";
            label = "ROOT";
            start = "513M";
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = ["noatime"];
              extraArgs = ["-L" "ROOT"];
            };
          };
        };
      };
    };
  };

  boot.loader.grub.enable = lib.mkForce false;
  fileSystems."/boot/efi".neededForBoot = true;
}
