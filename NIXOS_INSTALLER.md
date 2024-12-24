# Nix installation Guide

> https://nixos.org/manual/nixos/stable/#sec-installation-manual-summary

## Steps to Deploying

### 1. Preparing the USB installer

- Install balenaEtcher through `brew install --cask balenaetcher`
- Download the NixOS Minimal ISO image from [NixOS](https://nixos.org/download/)
- Format the USB drive to FAT32, as my laptop doesn't support Secure Boot
- Burn the ISO image to a USB drive

### 2. Connecting to the Internet

1. Connect to ethernet or Configure wifi

```bash
sudo systemctl start wpa_supplicant
wpa_cli -i wlan0
> scan
> scan_results
# add a new network, this command returns a network ID, which is 0 in this case.
> add_network
# associate the network with the network ID we just got
# NOTE: the quotes are required!
> set_network 0 ssid "<wifi_name>"
# for a WPA2 network, set the passphrase
# NOTE: the quotes are required!
> set_network 0 psk "xxx"
# enable the network
> enable_network 0
# save the configuration file
> save_config
# show the status
> status
```

### 3. Partitioning

- BIOS Systems (MBR)
  [REF](https://nixos.org/manual/nixos/stable/#sec-installation-manual-partitioning-MBR)

```bash
sudo su
parted /dev/sda -- mklabel msdos
parted /dev/sda -- mkpart primary 1MB -8GB
parted /dev/sda -- set 1 boot on
parted /dev/sda -- mkpart primary linux-swap -8GB 100%
```

- UEFI (GPT) [REF](https://nixos.org/manual/nixos/stable/#sec-installation-manual-partitioning-UEFI)

```bash
sudo su
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart root ext4 512MB -8GB
parted /dev/sda -- mkpart swap linux-swap -8GB 100%
parted /dev/sda -- mkpart ESP fat32 1MB 512MB
parted /dev/sda -- set 3 esp on
```

### 4. Formatting

- BIOS Systems (MBR)

```bash
mkfs.ext4 -L nixos /dev/sda1
mkswap -L swap /dev/sda2
swapon /dev/sda2
mount /dev/disk/by-label/nixos /mnt
```

- UEFI (GPT)

```bash
mkfs.ext4 -L nixos /dev/sda1
mkswap -L swap /dev/sda2
swapon /dev/sda2
mkfs.fat -F 32 -n boot /dev/sda3
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount -o umask=077 /dev/disk/by-label/boot /mnt/boot
```

### 5. Edit Base Configuration

#### Generate the NixOS Configuration

```bash
nixos-generate-config --root /mnt
```

#### Open the Configuration File

```bash
nano /mnt/etc/nixos/configuration.nix
```

#### Configure the Bootloader

- BIOS Systems (MBR)

```bash
boot.loader.grub.device = "/dev/sda";
```

- UEFI Systems (GPT)

```bash
## GRUB
boot.loader.grub.device = "nodev";
boot.loader.grub.efiSupport = true;

# Systemd-boot
boot.loader.systemd-boot.enable = true;
```

#### Other Configurations

```bash
nixpkgs.config.allowUnfree = true;
programs.neovim.enable = true;
services.openssh.enable = true;
services.openssh.settings.PasswordAuthentication = true;
services.openssh.settings.PermitRootLogin = "yes";
```

### 6. Install NixOS

```bash
nixos-install
reboot
```

### 7. Install Flake

```bash
# Enter an shell with just, git and neovim
nix-shell -p just git neovim

# Copy the fileSystems and swapDevices from the hardware-configuration.nix
cat /etc/nixos/hardware-configuration.nix

# !IMPORTANT: Add it to the hosts/shulab/hardware-configuration.nix and push it to the repo

# Install the flake
git clone https://github.com/ushiradineth/nix-config.git
cd nix-config
just build

mkdir -p /home/shu/nix-config
cp -r ./* /home/shu/nix-config
cp -r ./.* /home/shu/nix-config
sudo chown -R shu:shu ~/home/shu/nix-config
```
