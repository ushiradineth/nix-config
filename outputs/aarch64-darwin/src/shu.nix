{
  # NOTE: the args not used in this file CAN NOT be removed!
  # because haumea pass argument lazily,
  # and these arguments are used in the functions like `mylib.nixosSystem`, `mylib.colmenaSystem`, etc.
  inputs,
  lib,
  mylib,
  myvars,
  system,
  genSpecialArgs,
  ...
} @ args: let
  name = "shu";

  modules = {
    darwin-modules = map mylib.relativeToRoot [
      "modules/darwin"
      "hosts/${name}"
    ];
    home-modules = map mylib.relativeToRoot [
      "hosts/${name}/home.nix"
      "home/darwin"
    ];
  };

  systemArgs = modules // args;
in {
  # macOS's configuration
  darwinConfigurations.${name} = mylib.macosSystem systemArgs;
}
