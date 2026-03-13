{inputs, ...}: let
  helpers = import ../../lib/hosts.nix {inherit inputs;};
  currentSystem = builtins.currentSystem or "x86_64-linux";
  hosts = {
    shupi = import ./shupi.nix {inherit inputs;};
    shutm = import ./shutm.nix {inherit inputs;};
    shulab = import ./shulab.nix {inherit inputs;};
  };
in {
  flake.nixosConfigurations = builtins.mapAttrs (_: host: host.nixosConfiguration) hosts;

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
    // (builtins.mapAttrs (_: host: host.colmena) hosts);
}
