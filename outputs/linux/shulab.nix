{inputs, ...}: let
  hostname = "shulab";
  helpers = import ../../lib/hosts.nix {inherit inputs;};
  inherit
    (helpers)
    mylib
    mkLinuxNixosSystem
    ;
in {
  flake.nixosConfigurations = {
    ${hostname} = mkLinuxNixosSystem {
      inherit hostname;
      system = "x86_64-linux";
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
          inputs.agenix.nixosModules.default
          inputs.disko.nixosModules.disko
        ];
      home-modules = map mylib.relativeToRoot [
        "modules/home-manager/core/zsh"
        "modules/home-manager/core/btop.nix"
        "modules/home-manager/core/ssh.nix"
        "modules/home-manager/core/home.nix"
      ];
    };
  };
}
