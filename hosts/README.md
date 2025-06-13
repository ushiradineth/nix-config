# Hosts

1. `shu`: MacOS with Nix-Darwin on Macbook Pro 14-inch (2023), M2 Pro 10 Cores, 16GB RAM, 512GB SSD.
2. `shulab`: NixOS on Acer Aspire V3-572G Intel i5-4210U 2 Cores @ 1.70GHz, 6GB RAM, 1TB HDD.
3. `shuorb`: NixOS VM running on orbstack.

## How to add a new host

1. Under `hosts/`
   1. Create a new folder under `hosts/` with the name of the new host.
   2. Create & add the new host's `hardware-configuration.nix` to the new folder, and add the new
      host's `configuration.nix` to `hosts/<name>/default.nix`.
   3. If the new host need to use home-manager, add its custom config into `hosts/<name>/home.nix`.
1. Under `outputs/`
   1. Add a new nix file named `outputs/<system-architecture>/src/<name>.nix`.
   2. Copy the content from one of the existing similar host, and modify it to fit the new host.
      1. Usually, you only need to modify the `name` field.
