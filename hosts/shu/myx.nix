{
  config,
  hostname,
  mysecrets,
  myvars,
  pkgs,
  ...
}: let
  home = "/Users/${myvars.username}";
  directory = "${home}/.config/myx/nix";
  settings = {
    restore_on_startup = true;
    soloist = {
      directory = "${home}/.config/myx/soloist";
      sdk = "${home}/.config/myx/soloist/assets/soloist";
      device_name = "myx";
    };
  };
  package = pkgs.myx.override {
    configuration = {
      inherit settings directory;
      keySource = config.age.secrets.myx-soloist-api-key.path;
      clientIdSource = config.age.secrets.myx-spotify-client-id.path;
    };
  };
in {
  age.secrets = {
    myx-soloist-api-key = {
      file = "${mysecrets}/${hostname}/myx-soloist-api-key.age";
      owner = myvars.username;
      mode = "0600";
    };
    myx-spotify-client-id = {
      file = "${mysecrets}/${hostname}/myx-spotify-client-id.age";
      owner = myvars.username;
      mode = "0600";
    };
  };
  home-manager.users.${myvars.username} = {
    home.packages = [package];
    home.shellAliases.myx = "${package}/bin/myx";
    home.file."Applications/Myx.command" = {
      executable = true;
      text = ''
        #!${pkgs.runtimeShell}
        exec ${package}/bin/myx "$@"
      '';
    };
  };
}
