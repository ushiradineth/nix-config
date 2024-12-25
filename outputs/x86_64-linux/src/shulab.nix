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
  hostname = "shulab";

  modules = {
    nixos-modules = map mylib.relativeToRoot [
      "modules/linux"
      "modules/core"
      "modules/base.nix"
      "hosts/${hostname}"
    ];
    home-modules = map mylib.relativeToRoot [
      "home/linux/default.nix"
    ];
  };

  systemArgs = modules // args;
in {
  nixosConfigurations.${hostname} = mylib.nixosSystem systemArgs;
}
