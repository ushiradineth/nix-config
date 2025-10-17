{
  # NOTE: the args not used in this file CAN NOT be removed!
  # because haumea pass argument lazily,
  # and these arguments are used in the functions like `mylib.macosSystem` and `mylib.nixosSystem`
  inputs,
  lib,
  mylib,
  myvars,
  system,
  genSpecialArgs,
  nixvim,
  lanzaboote,
  disko,
  nixos-raspberrypi,
  agenix,
  ...
} @ args: let
  hostname = "shupi";
  tags = [hostname];
  ssh-user = "root";

  specialArgs = (genSpecialArgs system) // {inherit hostname;};

  modules = {
    nixos-modules =
      map mylib.relativeToRoot [
        "modules/nix-modules/core/base.nix"
        "modules/nix-modules/core/ssh.nix"
        "modules/nix-modules/linux/core.nix"
        "modules/nix-modules/linux/i18n.nix"
        "modules/nix-modules/linux/user.nix"
        "modules/nix-modules/linux/secrets.nix"
        "hosts/${hostname}"
      ]
      ++ [
        agenix.nixosModules.default
        lanzaboote.nixosModules.lanzaboote
        disko.nixosModules.disko
      ]
      ++ (with nixos-raspberrypi.nixosModules; [
        raspberry-pi-5.base

        # Required: Add necessary overlays with kernel, firmware, vendor packages
        nixos-raspberrypi.lib.inject-overlays

        # Binary cache with prebuilt packages for the currently locked `nixpkgs`,
        trusted-nix-caches

        #optimizations and fixes for issues arising from 16k memory page size (only for systems running default rpi5 (bcm2712) kernel)
        raspberry-pi-5.page-size-16k

        # Configures USB Gadget/Ethernet - Ethernet emulation over USB
        usb-gadget-ethernet
      ]);
    home-modules = map mylib.relativeToRoot [
      "modules/home-manager/core/zsh"
      "modules/home-manager/core/btop.nix"
      "modules/home-manager/core/ssh.nix"
      "modules/home-manager/core/home.nix"
    ];
  };

  systemArgs = modules // args // {inherit specialArgs;};
in {
  nixosConfigurations.${hostname} = mylib.nixosSystem systemArgs;
  colmena.${hostname} = mylib.colmenaSystem (systemArgs // {inherit tags ssh-user;});
}
