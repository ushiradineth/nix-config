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
      opencloud = 48004;
      adguard = 48005;
      prometheus = 48006;
      grafana = 48007;
      homepage = 48008;
    };
  };
}
