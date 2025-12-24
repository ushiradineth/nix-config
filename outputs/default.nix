{
  nixpkgs,
  pre-commit-hooks,
  nix-homebrew,
  nixvim,
  disko,
  nixos-raspberrypi,
  colmena,
  agenix,
  mysecrets,
  vicinae,
  zen-browser,
  ...
} @ inputs: let
  inherit (inputs.nixpkgs) lib;
  mylib = import ../lib {inherit lib;};
  myvars = import ../vars {inherit lib;};

  # Add custom lib, vars, nixpkgs instance, and all the inputs to specialArgs,
  genSpecialArgs = system:
    inputs
    // {
      inherit mylib myvars;

      pkgs-unstable = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    };

  args = {
    inherit
      inputs
      lib
      mylib
      myvars
      genSpecialArgs
      nix-homebrew
      nixvim
      disko
      nixos-raspberrypi
      colmena
      agenix
      mysecrets
      vicinae
      zen-browser
      ;
  };

  nixosSystems = {
    x86_64-linux = import ./x86_64-linux (args // {system = "x86_64-linux";});
    aarch64-linux = import ./aarch64-linux (args // {system = "aarch64-linux";});
  };
  darwinSystems = {
    aarch64-darwin = import ./aarch64-darwin (args // {system = "aarch64-darwin";});
  };
  allSystems = nixosSystems // darwinSystems;
  allSystemNames = builtins.attrNames allSystems;
  nixosSystemValues = builtins.attrValues nixosSystems;
  darwinSystemValues = builtins.attrValues darwinSystems;

  forAllSystems = func: (nixpkgs.lib.genAttrs allSystemNames func);
in {
  debugAttrs = {inherit nixosSystems darwinSystems allSystems allSystemNames;};

  nixosConfigurations = lib.attrsets.mergeAttrsList (map (it: it.nixosConfigurations or {}) nixosSystemValues);

  darwinConfigurations = lib.attrsets.mergeAttrsList (map (it: it.darwinConfigurations or {}) darwinSystemValues);

  colmena =
    {
      meta =
        (
          let
            system = builtins.currentSystem;
          in {
            nixpkgs = import nixpkgs {inherit system;};
            specialArgs = genSpecialArgs system;
          }
        )
        // {
          nodeNixpkgs = lib.attrsets.mergeAttrsList (
            map (it: it.colmenaMeta.nodeNixpkgs or {}) nixosSystemValues
          );
          nodeSpecialArgs = lib.attrsets.mergeAttrsList (
            map (it: it.colmenaMeta.nodeSpecialArgs or {}) nixosSystemValues
          );
        };
    }
    // lib.attrsets.mergeAttrsList (map (it: it.colmena or {}) nixosSystemValues);

  packages = forAllSystems (
    system: allSystems.${system}.packages or {}
  );

  checks = forAllSystems (
    system: {
      pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = mylib.relativeToRoot ".";
        hooks = {
          alejandra.enable = true;
          prettier = {
            enable = true;
            settings = {
              write = true;
              configPath = "./.prettierrc.yaml";
            };
          };
          deadnix.enable = true; # detect unused variable bindings in `*.nix`
          statix.enable = true; # lints and suggestions for Nix code(auto suggestions)
        };
      };
    }
  );

  formatter = forAllSystems (
    system: nixpkgs.legacyPackages.${system}.alejandra
  );
}
