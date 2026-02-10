# Raspberry Pi 5 NixOS Installation Guide

Complete guide for setting up NixOS on Raspberry Pi 5 (or any other Raspberry Pi but I haven't
tested it).

## Step 1: Build Custom Installer Image

Use the `nixos-raspberrypi` installer image and bake in your SSH key so you can log in on first
boot.

> Do this build on the Pi itself, it's gonna be slow if you do it on a mismatching architecture. Or
> enable cross-compilation on your build machine.
> `boot.binfmt.emulatedSystems = [ "aarch64-linux" ]`

```bash
git clone https://github.com/nvmd/nixos-raspberrypi
cd nixos-raspberrypi

# Add your SSH public key ()
$EDITOR flake.nix
# search for custom-user-config
# add public key to users.users.nixos.openssh.authorizedKeys.keys
# add public key to users.users.root.openssh.authorizedKeys.keys

# Build the Raspberry Pi 5 installer image
nix build .#installerImages.rpi5

# The result will be in ./result/sd-image/*.img.zst
ls -lh result/sd-image/
```

**Note**: The build process may take 15-30 minutes depending on your machine.

## Step 2: Flash the Image

### Extract the Image

```bash
# Requires zstd (provides unzstd)
# Extract the compressed image
unzstd nixos-installer-rpi5-kernel.img.zst

# OR move it to /tmp and extract it there
mv nixos-installer-rpi5-kernel.img.zst /tmp
cd /tmp
unzstd nixos-installer-rpi5-kernel.img.zst

# Now you should have `nixos-installer-rpi5-kernel.img`
```

### Flash to SD card

1. **Using dd (Linux/macOS)**:

   ```bash
   # Find your device (be very careful!)
   diskutil list  # macOS
   lsblk          # Linux

   # Unmount the device (macOS example)
   diskutil unmountDisk /dev/diskN
   # Unmount the device (Linux example)
   sudo umount /dev/sdX*

   # Flash the image (/dev/SDCARD = /dev/diskN on macOS, /dev/sdX on Linux)
   # macOS: /dev/rdiskN is faster than /dev/diskN
   sudo dd if=nixos-installer-rpi5-kernel.img of=/dev/SDCARD bs=4M status=progress

   # Sync and eject
   sync
   diskutil eject /dev/diskN
   ```

## Step 3: Deploy Configuration with nixos-anywhere

From your development machine:

```bash
cd ~/nix-config

# This will:
# - Partition and format the NVMe drive
# - Install NixOS with the full configuration
# - Set up disko partitioning scheme
just init shupi

# This will:
just deploy shupi
```

## Extra Steps

- Setup GPG and SSH keys
- Update nix-secrets with the SSH public key
- Add the SSH public key to `vars/default.nix`
