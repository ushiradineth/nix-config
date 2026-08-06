let
  flake = builtins.getFlake (toString ./.);
  inputs = flake.inputs // {self = flake;};
  helpers = import ./lib/hosts.nix {inherit inputs;};
  currentSystem = builtins.currentSystem or "x86_64-linux";
  hosts = helpers.scanColmenaHosts ./outputs/colmena;
in
  {
    meta = {
      nixpkgs = import inputs.nixpkgs {system = currentSystem;};
      specialArgs = helpers.genSpecialArgs currentSystem;
      nodeNixpkgs = {};
      nodeSpecialArgs = {};
    };
  }
  // builtins.mapAttrs (_: host: host.colmena) hosts
