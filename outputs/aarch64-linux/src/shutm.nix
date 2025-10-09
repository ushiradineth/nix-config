{
  inputs,
  lib,
  mylib,
  myvars,
  system,
  genSpecialArgs,
  disko,
  ...
} @ args: let
  hostname = "shutm";
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
        "hosts/${hostname}"
      ]
      ++ [disko.nixosModules.disko];
  };

  systemArgs = modules // args // {inherit specialArgs;};
in {
  nixosConfigurations.${hostname} = mylib.nixosSystem systemArgs;
  colmena.${hostname} = mylib.colmenaSystem (systemArgs // {inherit tags ssh-user;});
}
