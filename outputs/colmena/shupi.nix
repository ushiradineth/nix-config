{inputs}: let
  hostname = "shupi";
  system = "aarch64-linux";
  helpers = import ../../lib/hosts.nix {inherit inputs;};
  inherit
    (helpers)
    mylib
    mkLinuxNixosSystem
    mkColmenaSystem
    ;
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
      inputs.agenix.nixosModules.default
      inputs.disko.nixosModules.disko
    ]
    ++ (with inputs.nixos-raspberrypi.nixosModules; [
      raspberry-pi-5.base
      inputs.nixos-raspberrypi.lib.inject-overlays
      trusted-nix-caches
      raspberry-pi-5.page-size-16k
      usb-gadget-ethernet
    ]);

  home-modules = map mylib.relativeToRoot [
    "modules/home-manager/core/zsh"
    "modules/home-manager/core/btop.nix"
    "modules/home-manager/core/ssh.nix"
    "modules/home-manager/core/home.nix"
  ];
in {
  nixosConfiguration = mkLinuxNixosSystem {
    inherit hostname nixos-modules home-modules system;
  };

  colmena = mkColmenaSystem {
    tags = [hostname];
    ssh-user = "root";
    inherit hostname nixos-modules home-modules system;
  };
}
