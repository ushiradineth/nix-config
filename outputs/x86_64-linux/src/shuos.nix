{
  inputs,
  lib,
  mylib,
  myvars,
  system,
  genSpecialArgs,
  nixvim,
  vicinae,
  zen-browser,
  ...
} @ args: let
  hostname = "shuos";

  specialArgs = (genSpecialArgs system) // {inherit hostname;};

  modules = {
    nixos-modules = map mylib.relativeToRoot [
      "modules/nix-modules/linux"
      "modules/nix-modules/core"
      "hosts/${hostname}"
    ];
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
  nixosConfigurations.${hostname} = mylib.nixosSystem systemArgs;
}
