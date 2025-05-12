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
  hostname = "shuorb";

  modules = {
    nixos-modules = map mylib.relativeToRoot [
      "modules/base.nix"
      "modules/linux/core.nix"
      "modules/linux/i18n.nix"
      "modules/linux/packages.nix"
      "modules/linux/ssh.nix"
      "modules/linux/user.nix"
      "hosts/${hostname}"
    ];
    home-modules = map mylib.relativeToRoot [
      "home/base/btop.nix"
      "home/base/git.nix"
      "home/base/home.nix"
      "home/base/ssh.nix"
      "home/base/yazi.nix"
      "home/base/zsh.nix"
    ];
  };

  systemArgs = modules // args;
in {
  nixosConfigurations.${hostname} = mylib.nixosSystem systemArgs;
}
