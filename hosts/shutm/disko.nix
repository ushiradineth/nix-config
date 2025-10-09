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
            start = "1MiB";
            size = "512MiB";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["fmask=0022" "dmask=0022"];
              extraArgs = ["-n" "BOOT"];
            };
          };
          root = {
            type = "8300";
            label = "ROOT";
            start = "513MiB";
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
  fileSystems."/boot".neededForBoot = true;
}
