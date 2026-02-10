{
  inputs,
  lib,
  mylib,
  myvars,
  system,
  genSpecialArgs,
  nixvim,
  agenix,
  disko,
  ...
} @ args: let
  hostname = "shulab";

  specialArgs = (genSpecialArgs system) // {inherit hostname;};

  modules = {
    nixos-modules =
      map mylib.relativeToRoot [
        "modules/nix-modules/core/base.nix"
        "modules/nix-modules/core/ssh.nix"
        "modules/nix-modules/linux/core.nix"
        "modules/nix-modules/linux/i18n.nix"
        "modules/nix-modules/linux/user.nix"
        "modules/nix-modules/linux/secrets.nix"
        "hosts/${hostname}"
      ]
      ++ [
        agenix.nixosModules.default
        disko.nixosModules.disko
      ];
    home-modules = map mylib.relativeToRoot [
      "modules/home-manager/core/zsh"
      "modules/home-manager/core/btop.nix"
      "modules/home-manager/core/ssh.nix"
      "modules/home-manager/core/home.nix"
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
        nixvim
        ;
    };
in {
  nixosConfigurations.${hostname} = mylib.nixosSystem systemArgs;
}
