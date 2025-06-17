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
  ...
} @ args: let
  hostname = "shu";

  modules = {
    darwin-modules =
      (map mylib.relativeToRoot [
        "modules/nix-modules/darwin"
        "modules/nix-modules/core"
        "hosts/${hostname}"
      ])
      ++ [nix-homebrew.darwinModules.nix-homebrew];
    home-modules = map mylib.relativeToRoot [
      "modules/home-manager/darwin"
    ];
  };

  systemArgs = modules // args;
in {
  darwinConfigurations.${hostname} = mylib.macosSystem systemArgs;
}
