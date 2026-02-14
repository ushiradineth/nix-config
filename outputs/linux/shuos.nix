{inputs, ...}: let
  hostname = "shuos";
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
          inputs.nixvim.homeModules.nixvim
          inputs.vicinae.homeManagerModules.default
          inputs.zen-browser.homeModules.beta
        ];
    };
  };
}
