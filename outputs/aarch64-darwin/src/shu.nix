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
  nix-homebrew,
  nixvim,
  ...
} @ args: let
  hostname = "shu";

  specialArgs = (genSpecialArgs system) // {inherit hostname;};

  modules = {
    darwin-modules =
      (map mylib.relativeToRoot [
        "modules/nix-modules/darwin"
        "modules/nix-modules/core"
        "hosts/${hostname}"
      ])
      ++ [nix-homebrew.darwinModules.nix-homebrew];
    home-modules =
      map mylib.relativeToRoot [
        "modules/home-manager/darwin"
      ]
      ++ [nixvim.homeManagerModules.nixvim];
  };

  systemArgs = modules // args // {inherit specialArgs;};
in {
  darwinConfigurations.${hostname} = mylib.macosSystem systemArgs;
}
