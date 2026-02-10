# Library

Some helper functions, used by `flake.nix` to reduce code duplication and make it easier to add new
machines:

1. `attrs.nix`: A set of functions to manipulate attribute sets.
2. `macosSystem.nix`: A function to generate config for
   macOS([nix-darwin](https://github.com/LnL7/nix-darwin)).
3. `nixosSystem.nix`: A function to generate config for NixOS.
4. `default.nix`: import all the above functions, and some custom useful functions, and export them
   as a single attribute set.
5. `colmenaSystem.nix`: A function to generate config for Colmena.
6. `docker-helpers.nix`: A set of helper functions to abstract docker config logic. (shupi)
7. `traefik-helpers.nix`: A set of helper functions to abstract traefik config logic. (shupi)
