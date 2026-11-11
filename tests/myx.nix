{
  lib,
  pkgs,
}: let
  agePaths = {
    myx-soloist-api-key.path = "/runtime/age/soloist";
    myx-spotify-client-id.path = "/runtime/age/spotify";
  };
  module = import ../hosts/shu/myx.nix {
    config.age.secrets = agePaths;
    hostname = "fixture";
    mysecrets = "/encrypted";
    myvars.username = "fixture";
    pkgs = {
      myx.override = arguments: arguments // {__toString = _: "/package/myx";};
      runtimeShell = "/bin/sh";
    };
  };
  package = builtins.head module.home-manager.users.fixture.home.packages;
  settings = package.configuration.settings;
in
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
    import ./myx-setup.nix {inherit pkgs;}
