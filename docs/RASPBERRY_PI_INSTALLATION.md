# Raspberry Pi 5 NixOS Installation Guide

Complete guide for setting up NixOS on Raspberry Pi 5 (or any other Raspberry Pi but I haven't tested it).

## Build Custom Installer Image

Use the `nixos-raspberrypi` installer image and bake in your SSH key so you can log in on first boot.

> Do this build on the Pi itself, it's gonna be slow if you do it on a mismatching architecture.
> Or enable cross-compilation on your build machine. `boot.binfmt.emulatedSystems = [ "aarch64-linux" ]`

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
# Extract the compressed image
unzstd nixos-installer-rpi5-kernel.img.zst

# OR move it to /tmp and extract it there
mv nixos-installer-rpi5-kernel.img.zst /tmp
cd /tmp
unzstd nixos-installer-rpi5-kernel.img.zst

# Now you should have `nixos-installer-rpi5-kernel.img`
```

### Flash to NVMe Drive

1. **Using balenaEtcher**:
   - Open balenaEtcher
   - Select the extracted `.img` file
   - Select your NVMe drive (via USB adapter or directly if supported)
   - Click "Flash!"
   - Wait for verification to complete

2. **Using dd (Linux/macOS)**:

   ```bash
   # Find your device (be very careful!)
   diskutil list  # macOS
   lsblk          # Linux

   # Unmount the device (macOS example)
   diskutil unmountDisk /dev/void

   # Flash the image (replace /dev/void with your device)
   sudo dd if=nixos-installer-rpi5-kernel.img of=/dev/void bs=4M status=progress

   # Sync and eject
   sync
   diskutil eject /dev/void
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
