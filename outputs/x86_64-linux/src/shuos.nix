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
  ...
} @ args: let
  hostname = "shuos";

  modules = {
    nixos-modules = map mylib.relativeToRoot [
      "modules/nix-modules/linux"
      "modules/nix-modules/core/base.nix"
      "modules/nix-modules/core/fonts.nix"
      "modules/nix-modules/core/ssh.nix"
      "hosts/${hostname}"
    ];
    home-modules =
      map mylib.relativeToRoot [
        "modules/home-manager/linux"
      ]
      ++ [nixvim.homeManagerModules.nixvim];
  };

  systemArgs = modules // args;
in {
  nixosConfigurations.${hostname} = mylib.nixosSystem systemArgs;
}
