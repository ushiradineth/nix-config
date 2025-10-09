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

  specialArgs = (genSpecialArgs system) // {inherit hostname;};

  modules = {
    nixos-modules =
      map mylib.relativeToRoot [
        "modules/nix-modules/linux"
        "modules/nix-modules/core/base.nix"
        "modules/nix-modules/core/ssh.nix"
        "hosts/${hostname}"
      ]
      ++ [disko.nixosModules.disko];
  };

  systemArgs = modules // args // {inherit specialArgs;};
in {
  nixosConfigurations.${hostname} = mylib.nixosSystem systemArgs;
}
