{
  # NOTE: the args not used in this file CAN NOT be removed!
  # because haumea pass argument lazily,
  # and these arguments are used in the functions like `mylib.nixosSystem`
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
        "modules/darwin"
        "modules/core"
        "modules/base.nix"
        "hosts/${hostname}"
      ])
      ++ [nix-homebrew.darwinModules.nix-homebrew];
    home-modules = map mylib.relativeToRoot [
      "home/darwin/default.nix"
    ];
  };

  systemArgs = modules // args;
in {
  # macOS's configuration
  darwinConfigurations.${hostname} = mylib.macosSystem systemArgs;
}
