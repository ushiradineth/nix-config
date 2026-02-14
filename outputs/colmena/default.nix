{inputs, ...}: let
  helpers = import ../../lib/hosts.nix {inherit inputs;};
  currentSystem = builtins.currentSystem or "x86_64-linux";
in {
  flake.colmena =
    {
      meta =
        {
          nixpkgs = import inputs.nixpkgs {system = currentSystem;};
          specialArgs = helpers.genSpecialArgs currentSystem;
        }
        // {
          nodeNixpkgs = {};
          nodeSpecialArgs = {};
        };
    }
    // {
      shupi = import ./shupi.nix {inherit inputs;};
      shutm = import ./shutm.nix {inherit inputs;};
    };
}
