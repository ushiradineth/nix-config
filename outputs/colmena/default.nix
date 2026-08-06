{inputs, ...}: let
  helpers = import ../../lib/hosts.nix {inherit inputs;};
  hosts = helpers.scanColmenaHosts ./.;
in {
  flake.nixosConfigurations = builtins.mapAttrs (_: host: host.nixosConfiguration) hosts;
}
