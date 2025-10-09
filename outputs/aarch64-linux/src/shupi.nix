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
  ...
} @ args: let
  hostname = "shupi";

  specialArgs = (genSpecialArgs system) // {inherit hostname;};

  modules = {
    nixos-modules =
      map mylib.relativeToRoot [
        "modules/nix-modules/core/base.nix"
        "modules/nix-modules/core/ssh.nix"
        "modules/nix-modules/linux/core.nix"
        "modules/nix-modules/linux/i18n.nix"
        "modules/nix-modules/linux/user.nix"
        "hosts/${hostname}"
      ]
      ++ [lanzaboote.nixosModules.lanzaboote]
      ++ [disko.nixosModules.disko]
      ++ [
        nixos-raspberrypi.lib.inject-overlays
        nixos-raspberrypi.lib.inject-overlays-global
      ]
      ++ (with nixos-raspberrypi.nixosModules; [
        trusted-nix-caches
        nixpkgs-rpi
        raspberry-pi-5.base
        usb-gadget-ethernet
        raspberry-pi-5.page-size-16k
        raspberry-pi-5.display-vc4
        raspberry-pi-5.bluetooth
      ]);
    home-modules =
      map mylib.relativeToRoot [
        "modules/home-manager/linux"
      ]
      ++ [nixvim.homeManagerModules.nixvim];
  };

  systemArgs = modules // args // {inherit specialArgs;};
in {
  nixosConfigurations.${hostname} = mylib.nixosSystem systemArgs;
}
