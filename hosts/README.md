# Hosts

1. `shu`: MacOS with Nix-Darwin on Macbook Pro 14-inch (2023), M2 Pro 10 Cores, 16GB RAM, 512GB SSD.
2. `shulab`: NixOS on Acer Aspire V3-572G Intel i5-4210U 2 Cores @ 1.70GHz, 6GB RAM, 1TB HDD.
3. `shuos`: NixOS on AMD Ryzen 7 3700X 8-Cores @ 4.40GHz, Nvidia GTX 1660 6GB, 16GB RAM, 2TB SSD.
4. `shupi`: NixOS on Raspberry Pi 5 8GB RAM, 1TB NVMe SSD.
5. `shutm`: NixOS VM running on MacOS UTM.

## How to add a new host

- Under `hosts/`
  1.  Create a new folder under `hosts/` with the name of the new host.
  2.  Copy the new host's `hardware-configuration.nix` to the above created folder, and add the new
      host's `configuration.nix` to `hosts/<name>/default.nix`.
- Under `outputs/`
  1.  Add a new nix file named `outputs/<system-architecture>/src/<name>.nix`.
  2.  Copy the content from one of the existing similar host, and modify it to fit the new host.
      1. Usually, you only need to modify the `name` field.
- In `vars/default.nix`, add the new host's name under `hostAddresses`.
