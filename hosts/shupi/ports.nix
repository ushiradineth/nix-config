{
  lib,
  myvars,
  ...
}: {
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
      opencloud = 48004;
      adguard = 48005;
      umami = 48006;
      prometheus = 48007;
      grafana = 48008;
      netdata = 48009;
      cockpit = 48010;
    };
  };
}
