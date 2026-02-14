{inputs}: let
  hostname = "shupi";
  helpers = import ../../lib/hosts.nix {inherit inputs;};
  inherit
    (helpers)
    mylib
    mkColmenaSystem
    ;
in
  mkColmenaSystem {
    inherit hostname;
    system = "aarch64-linux";
    tags = ["shupi"];
    ssh-user = "root";
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
  }
