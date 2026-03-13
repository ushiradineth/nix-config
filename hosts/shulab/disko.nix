_: {
  disko = {
    enableConfig = true;
    rootMountPoint = "/mnt";
    devices.disk.main = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            label = "ESP";
            type = "EF00";
            start = "1M";
            size = "512M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["fmask=0022" "dmask=0022"];
              extraArgs = ["-F32" "-n" "ESP"];
            };
          };
          root = {
            label = "NIXOS";
            type = "8300";
            start = "513M";
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = ["noatime"];
              extraArgs = ["-L" "NIXOS"];
            };
          };
        };
      };
    };
  };
}
