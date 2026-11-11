{
  lib,
  pkgs,
}: let
  agePaths = {
    myx-soloist-api-key.path = "/runtime/age/soloist";
    myx-spotify-client-id.path = "/runtime/age/spotify";
  };
  evaluate = settings:
    (lib.evalModules {
      specialArgs = {
        hostname = "fixture";
        mysecrets = "/encrypted";
        myvars.username = "fixture";
        pkgs = {
          callPackage = _: arguments: arguments // {__toString = _: "/package/myx";};
          runtimeShell = "/bin/sh";
        };
      };
      modules = [
        ../default.nix
        {
          options.age.secrets = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = {};
          };
          options.home-manager.users = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = {};
          };
          config = settings;
        }
      ];
    }).config;
  disabled = evaluate {};
  module = evaluate {
    programs.myx.enable = true;
    age.secrets = agePaths;
  };
  package = builtins.head module.home-manager.users.fixture.home.packages;
  settings = package.configuration.settings;
in
  assert !disabled.programs.myx.enable;
  assert disabled.age.secrets == {};
  assert disabled.home-manager.users == {};
  assert !(settings ? client_id || settings ? client_secret);
  assert !(settings.soloist ? api_key_file);
  assert !(settings.soloist ? api_key);
  assert package.configuration.clientIdSource == agePaths.myx-spotify-client-id.path;
  assert package.configuration.keySource == agePaths.myx-soloist-api-key.path;
  assert lib.all (name:
    module.age.secrets.${name}.owner
    == "fixture"
    && module.age.secrets.${name}.mode == "0600"
    && lib.hasSuffix ".age" module.age.secrets.${name}.file)
  ["myx-soloist-api-key" "myx-spotify-client-id"];
    import ./setup.nix {inherit pkgs;}
