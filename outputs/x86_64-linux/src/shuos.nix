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
  vicinae,
  zen-browser,
  ...
} @ args: let
  hostname = "shuos";

  specialArgs = (genSpecialArgs system) // {inherit hostname;};

  modules = {
    nixos-modules =
      map mylib.relativeToRoot [
        "modules/nix-modules/linux"
        "modules/nix-modules/core"
        "hosts/${hostname}"
      ]
      ++ [lanzaboote.nixosModules.lanzaboote];
    home-modules =
      map mylib.relativeToRoot [
        "modules/home-manager/linux"
      ]
      ++ [
        nixvim.homeModules.nixvim
        vicinae.homeManagerModules.default
        zen-browser.homeModules.beta
      ];
  };

  systemArgs = modules // args // {inherit specialArgs;};
in {
  nixosConfigurations.${hostname} = mylib.nixosSystem systemArgs;
}
