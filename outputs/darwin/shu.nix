{inputs, ...}: let
  hostname = "shu";
  helpers = import ../../lib/hosts.nix {inherit inputs;};
  inherit
    (helpers)
    mylib
    mkDarwinSystem
    ;
in {
  flake.darwinConfigurations = {
    ${hostname} = mkDarwinSystem {
      inherit hostname;
      system = "aarch64-darwin";
      darwin-modules =
        map mylib.relativeToRoot [
          "modules/nix-modules/darwin"
          "modules/nix-modules/core"
          "hosts/${hostname}"
        ]
        ++ [
          inputs.nix-homebrew.darwinModules.nix-homebrew
        ];
      home-modules =
        map mylib.relativeToRoot [
          "modules/home-manager/darwin"
        ]
        ++ [inputs.nixvim.homeModules.nixvim];
    };
  };
}
