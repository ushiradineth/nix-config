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
      adguard = 48005;
      prometheus = 48006;
      grafana = 48007;
      homepage = 48008;
      immich = 48009;
      seafile = 48010;
      umami = 48011;
    };
  };
}
