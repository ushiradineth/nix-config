{lib, ...}: {
  options.ports = lib.mkOption {
    type = lib.types.attrs;
    default = {};
    description = "Centralized port configuration for shupi services";
  };

  config = {
    ports = {
      actualbudget = 48001;
      portainer = 48002;
      uptimekuma = 48003;
      couchdb = 48004;
      adguard = 48005;
      victoriametrics = 48006;
      victorialogs = 48007;
      homepage = 48008;
      immich = 48009;
      seafile = 48010;
      umami = 48011;
      wakapi = 48012;
      # infisical = 48013;
      backrest = 48014;
      ntfy = 48015;
      alertmanager = 48016;
      alertmanager-ntfy = 48017;
      forgejo = 48018;
      cadvisor = 48019;
      nodeExporter = 48020;
      vmagent = 48021;
    };
  };
}
