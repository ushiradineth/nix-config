{inputs}: let
  hostname = "shutm";
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
      "hosts/${hostname}"
    ]
    ++ [inputs.disko.nixosModules.disko];
in {
  nixosConfiguration = mkLinuxNixosSystem {
    inherit hostname nixos-modules system;
  };

  colmena = mkColmenaSystem {
    tags = [hostname];
    ssh-user = "root";
    inherit hostname nixos-modules system;
  };
}
