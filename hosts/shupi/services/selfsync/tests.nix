{
  host,
  pkgs,
}: let
  container = host.virtualisation.oci-containers.containers.selfsync;
  http = host.services.traefik.dynamicConfigOptions.http;
in
  assert container.ports == ["127.0.0.1:48030:8085"];
  assert container.user == "65532:65532";
  assert http.services.selfsync.loadBalancer.servers == [{url = "http://127.0.0.1:48030";}];
  assert http.routers.selfsync.middlewares == ["selfsync-tailnet"];
  assert http.middlewares.selfsync-tailnet.ipAllowList.sourceRange == ["100.64.0.0/10" "fd7a:115c:a1e0::/48"];
  assert !(builtins.elem 48030 host.networking.firewall.allowedTCPPorts);
  assert builtins.elem "/srv/selfsync/backups" host.services.restic.backups.app-data.paths;
  assert builtins.elem "selfsync-backup.service" host.systemd.services.restic-backups-app-data.requires;
    pkgs.runCommand "shupi-selfsync" {} ''
      touch "$out"
    ''
