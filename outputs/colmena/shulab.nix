{inputs}: let
  hostname = "shulab";
  helpers = import ../../lib/hosts.nix {inherit inputs;};
  inherit
    (helpers)
    mylib
    mkColmenaSystem
    ;
in
  mkColmenaSystem {
    inherit hostname;
    system = "x86_64-linux";
    tags = ["shulab"];
    ssh-user = "root";
    nixos-modules =
      map mylib.relativeToRoot [
        "modules/nix-modules/core/base.nix"
        "modules/nix-modules/core/ssh.nix"
        "modules/nix-modules/linux/core.nix"
        "modules/nix-modules/linux/i18n.nix"
        "modules/nix-modules/linux/user.nix"
        "hosts/${hostname}"
      ]
      ++ [
        inputs.disko.nixosModules.disko
      ];
    home-modules = map mylib.relativeToRoot [
      "modules/home-manager/core/zsh"
      "modules/home-manager/core/cli.nix"
      "modules/home-manager/core/btop.nix"
      "modules/home-manager/core/ssh.nix"
      "modules/home-manager/core/home.nix"
    ];
  }
