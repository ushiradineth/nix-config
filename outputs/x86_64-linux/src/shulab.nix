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
  name = "shulab";

  modules = {
    nixos-modules = map mylib.relativeToRoot [
      "modules/linux/server.nix"
      "hosts/${name}"
    ];
    home-modules = map mylib.relativeToRoot [
      "hosts/${name}/home.nix"
      "home/linux"
    ];
  };

  systemArgs = modules // args;
in {
  nixosConfigurations.${name} = mylib.nixosSystem systemArgs;
}
