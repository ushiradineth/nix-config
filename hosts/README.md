# Hosts

1. `shu`: MacOS with Nix-Darwin on Macbook Pro 14-inch (2023), M2 Pro 10 Cores, 16GB RAM, 512GB SSD.
2. `shulab`: NixOS on Acer Aspire V3-572G Intel i5-4210U 2 Cores @ 1.70GHz, 6GB RAM, 1TB HDD.
3. `shuos`: NixOS on AMD Ryzen 7 3700X 8-Cores @ 4.40GHz, Nvidia GTX 1660 6GB, 16GB RAM, 2TB SSD.
4. `shupi`: NixOS on Raspberry Pi 5 8GB RAM, 1TB NVMe SSD.
5. `shutm`: NixOS VM running on MacOS UTM.

## How to add a new host

- Under `hosts/`
  1. Create `hosts/<hostname>/`.
  2. Add `hosts/<hostname>/default.nix`.
  3. For NixOS machines, add `hosts/<hostname>/hardware-configuration.nix` and import it from
     `default.nix`.

- Under `outputs/`
  1. Pick one or more target outputs for this host:
     - `outputs/linux/<hostname>.nix` for NixOS nodes
     - `outputs/darwin/<hostname>.nix` for MacOS nodes
     - `outputs/colmena/<hostname>.nix` for Colmena deployment nodes
  2. No registration is needed for Linux/Darwin host files; they are auto-imported by
     `outputs/linux/default.nix` and `outputs/darwin/default.nix`.
  3. For Colmena nodes, register the file in `outputs/colmena/default.nix`.

- Style conventions for each output file
  1. Define `hostname` in a `let` block and `inherit hostname` in the `mk*System` call.
  2. Use `"hosts/${hostname}"` in module paths.
  3. Inline `nixos-modules`, `darwin-modules`, and `home-modules` directly in the `mk*System` call
     (no separate module list variables).

- Shared host registry
  1. Add the hostname under `hostAddresses` in `vars/default.nix`.
  2. Set the host architecture directly in its output file via `system = "..."`.
