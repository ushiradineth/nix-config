# Library

Some helper functions, used by `flake.nix` to reduce code duplication and make it easier to add new
machines:

1. `attrs.nix`: A set of functions to manipulate attribute sets.
2. `macosSystem.nix`: A function to generate config(attribute set) for
   macOS([nix-darwin](https://github.com/LnL7/nix-darwin)).
3. `nixosSystem.nix`: A function to generate config(attribute set) for NixOS.
4. `default.nix`: import all the above functions, and some custom useful functions, and export them
   as a single attribute set.
