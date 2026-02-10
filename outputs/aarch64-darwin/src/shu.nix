{
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
      ++ [
        nix-homebrew.darwinModules.nix-homebrew
      ];
    home-modules =
      map mylib.relativeToRoot [
        "modules/home-manager/darwin"
      ]
      ++ [nixvim.homeModules.nixvim];
  };

  systemArgs =
    modules
    // args
    // {
      inherit
        specialArgs
        inputs
        lib
        myvars
        ;
    };
in {
  darwinConfigurations.${hostname} = mylib.macosSystem systemArgs;
}
