{inputs}: let
  inherit (inputs.nixpkgs) lib;

  mylib = import ./default.nix {inherit lib;};

  myvars = import ../vars {inherit lib;};

  genSpecialArgs = system:
    inputs
    // {
      inherit mylib myvars;

      pkgs-unstable = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    };

  mkLinuxNixosSystem = {
    hostname,
    system,
    nixos-modules,
    home-modules ? [],
  }:
    mylib.nixosSystem {
      inherit
        inputs
        lib
        system
        genSpecialArgs
        nixos-modules
        home-modules
        myvars
        ;
      specialArgs = (genSpecialArgs system) // {inherit hostname;};
    };

  mkDarwinSystem = {
    hostname,
    system,
    darwin-modules,
    home-modules ? [],
  }:
    mylib.macosSystem {
      inherit
        inputs
        lib
        system
        genSpecialArgs
        darwin-modules
        home-modules
        myvars
        ;
      specialArgs = (genSpecialArgs system) // {inherit hostname;};
    };

  mkColmenaSystem = {
    hostname,
    system,
    tags,
    ssh-user,
    nixos-modules,
    home-modules ? [],
  }:
    mylib.colmenaSystem {
      inherit
        inputs
        lib
        system
        tags
        ssh-user
        genSpecialArgs
        nixos-modules
        home-modules
        myvars
        ;
      specialArgs = (genSpecialArgs system) // {inherit hostname;};
    };
in {
  inherit
    mylib
    genSpecialArgs
    mkLinuxNixosSystem
    mkDarwinSystem
    mkColmenaSystem
    ;
}
