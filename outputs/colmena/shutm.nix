{inputs}: let
  hostname = "shutm";
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
    tags = ["shutm"];
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
      ++ [inputs.disko.nixosModules.disko];
  }
