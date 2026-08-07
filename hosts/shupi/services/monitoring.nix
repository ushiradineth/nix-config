{
  config,
  lib,
  mylib,
  ...
}: let
  vmPort = config.ports.victoriametrics;
  vlPort = config.ports.victorialogs;
  cadvisorPort = config.ports.cadvisor;
  nodeExporterPort = config.ports.nodeExporter;
  vmagentPort = config.ports.vmagent;
  vmDomain = config.environment.variables.VICTORIAMETRICS_DOMAIN;
  vlDomain = config.environment.variables.VICTORIALOGS_DOMAIN;
in
  lib.mkMerge [
    {
      virtualisation.oci-containers.containers.victoriametrics = {
        image = "victoriametrics/victoria-metrics:v1.135.0@sha256:647f1a19274a362692c0968b926f4acecfdac9488bbf70f1985925d1717063b5";
        autoStart = true;
        ports = ["127.0.0.1:${toString vmPort}:8428"];
        extraOptions = ["--network=monitoring"];
        cmd = [
          "-storageDataPath=/victoria-metrics-data"
          "-retentionPeriod=12"
          "-vmalert.proxyURL=http://vmalert:8880"
        ];
        volumes = [
          "/srv/victoriametrics:/victoria-metrics-data"
        ];
      };

      virtualisation.oci-containers.containers.victorialogs = {
        image = "victoriametrics/victoria-logs:v1.45.0@sha256:01bfa0f80d8d6134753b0be0f206c3458f74a14e81bb570f8c3d2f20af2a24a0";
        autoStart = true;
        ports = ["127.0.0.1:${toString vlPort}:9428"];
        extraOptions = ["--network=monitoring"];
        cmd = [
          "-storageDataPath=/victoria-logs-data"
        ];
        volumes = [
          "/srv/victorialogs:/victoria-logs-data"
        ];
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/vector 0755 root root -"
        "d /srv/vector-config 0755 root root -"
      ];

      environment.etc."srv/vector-config/vector.toml".text = ''
        [sources.journald]
        type = "journald"
        current_boot_only = false

        [sources.docker]
        type = "docker_logs"

        [sinks.victorialogs]
        type = "http"
        inputs = ["journald", "docker"]
        uri = "http://victorialogs:9428/insert/jsonline?_stream_fields=host&_msg_field=message&_time_field=timestamp"
        encoding.codec = "json"
        framing.method = "newline_delimited"
        compression = "gzip"
      '';

      virtualisation.oci-containers.containers.vector = {
        image = "timberio/vector:0.51.1-debian@sha256:31c01788f10c47530a99a51bb22d37582d557e3b8edd02dc5bd62f58b2659e34";
        autoStart = true;
        extraOptions = [
          "--network=monitoring"
          "--privileged"
        ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock:ro"
          "/var/log/journal:/var/log/journal:ro"
          "/run/systemd/journal:/run/systemd/journal:ro"
          "/etc/machine-id:/etc/machine-id:ro"
          "/etc/srv/vector-config/vector.toml:/etc/vector/vector.toml:ro"
        ];
        cmd = ["--config" "/etc/vector/vector.toml"];
      };

      virtualisation.oci-containers.containers.cadvisor = {
        image = "ghcr.io/google/cadvisor:v0.60.5@sha256:763aecf1c32c2be8a1a75f9abfc2fc461005c9dbbaa39cb356b354aac1296dbe";
        autoStart = true;
        ports = ["127.0.0.1:${toString cadvisorPort}:8080"];
        extraOptions = [
          "--network=monitoring"
          "--privileged"
        ];
        volumes = [
          "/:/rootfs:ro"
          "/var/run:/var/run:ro"
          "/sys:/sys:ro"
          "/var/lib/docker/:/var/lib/docker:ro"
          "/dev/disk/:/dev/disk:ro"
        ];
        cmd = [
          "--docker_only=true"
          "--store_container_labels=true"
          "--containerd=/var/run/docker/containerd/containerd.sock"
        ];
      };

      systemd.services.docker-cadvisor = {
        unitConfig.StartLimitIntervalSec = 0;
        serviceConfig = {
          Restart = lib.mkForce "always";
          RestartSec = "30s";
        };
      };

      environment.etc."srv/prometheus-config/prometheus.yml".text = ''
        global:
          scrape_interval: 15s

        scrape_configs:
          - job_name: 'node'
            static_configs:
              - targets: ['127.0.0.1:${toString nodeExporterPort}']
                labels:
                  instance: 'shupi'

          - job_name: 'cadvisor'
            static_configs:
              - targets: ['127.0.0.1:${toString cadvisorPort}']
                labels:
                  instance: 'shupi'
      '';

      # Alert rules for vmalert
      environment.etc."srv/prometheus-config/alerts.yml".text = ''
        groups:
          - name: system_alerts
            interval: 1m
            rules:
              # High CPU usage
              - alert: HighCPUUsage
                expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
                for: 5m
                labels:
                  severity: warning
                annotations:
                  summary: "High CPU usage on {{ $labels.instance }}"
                  description: "CPU usage is above 80% (current value: {{ $value | humanize }}%)"

              # Critical CPU usage
              - alert: CriticalCPUUsage
                expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 95
                for: 2m
                labels:
                  severity: critical
                annotations:
                  summary: "Critical CPU usage on {{ $labels.instance }}"
                  description: "CPU usage is above 95% (current value: {{ $value | humanize }}%)"

              # High memory usage
              - alert: HighMemoryUsage
                expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 80
                for: 5m
                labels:
                  severity: warning
                annotations:
                  summary: "High memory usage on {{ $labels.instance }}"
                  description: "Memory usage is above 80% (current value: {{ $value | humanize }}%)"

              # Critical memory usage
              - alert: CriticalMemoryUsage
                expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 95
                for: 2m
                labels:
                  severity: critical
                annotations:
                  summary: "Critical memory usage on {{ $labels.instance }}"
                  description: "Memory usage is above 95% (current value: {{ $value | humanize }}%)"

              # Low disk space
              - alert: LowDiskSpace
                expr: 100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100) > 75
                for: 5m
                labels:
                  severity: warning
                annotations:
                  summary: "Low disk space on {{ $labels.instance }}"
                  description: "Disk usage is above 75% (current value: {{ $value | humanize }}%)"

              # Critical disk space
              - alert: CriticalDiskSpace
                expr: 100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100) > 85
                for: 2m
                labels:
                  severity: critical
                annotations:
                  summary: "Critical disk space on {{ $labels.instance }}"
                  description: "Disk usage is above 85% (current value: {{ $value | humanize }}%)"

              # Root filesystem predicted to run low soon
              - alert: RootFilesystemFillingSoon
                expr: predict_linear(node_filesystem_avail_bytes{mountpoint="/"}[6h], 24 * 3600) < 100 * 1024 * 1024 * 1024
                for: 15m
                labels:
                  severity: warning
                annotations:
                  summary: "Root filesystem is filling quickly on {{ $labels.instance }}"
                  description: "Available root disk is projected below 100 GiB within 24 hours."

              # System load high
              - alert: HighSystemLoad
                expr: node_load5 > 4
                for: 5m
                labels:
                  severity: warning
                annotations:
                  summary: "High system load on {{ $labels.instance }}"
                  description: "5-minute load average is high (current value: {{ $value | humanize }})"
      '';

      virtualisation.oci-containers.containers.vmagent = {
        image = "victoriametrics/vmagent:v1.135.0@sha256:9054315db53dbafc8f85afad63232081ee5d699b10200173cb9cbe2d6b2c74d7";
        autoStart = true;
        extraOptions = [
          "--network=host"
        ];
        cmd = [
          "-promscrape.config=/etc/prometheus/prometheus.yml"
          "-remoteWrite.url=http://127.0.0.1:${toString vmPort}/api/v1/write"
          "-httpListenAddr=127.0.0.1:${toString vmagentPort}"
        ];
        volumes = [
          "/srv/vmagent:/vmagent-data"
          "/etc/srv/prometheus-config/prometheus.yml:/etc/prometheus/prometheus.yml:ro"
        ];
      };

      # vmalert for processing alert rules
      virtualisation.oci-containers.containers.vmalert = {
        image = "victoriametrics/vmalert:v1.135.0@sha256:fe9a738c9b5f3419100c41a9343a889231ef0570ec01f6d5a5094f417714328d";
        autoStart = true;
        extraOptions = [
          "--network=monitoring"
          "--add-host=host.docker.internal:host-gateway"
        ];
        cmd = [
          "-datasource.url=http://victoriametrics:8428"
          "-notifier.url=http://alertmanager:9093"
          "-remoteWrite.url=http://victoriametrics:8428"
          "-remoteRead.url=http://victoriametrics:8428"
          "-rule=/etc/prometheus/alerts.yml"
          "-external.url=https://${vmDomain}"
          "-evaluationInterval=1m"
          "-httpListenAddr=:8880"
        ];
        volumes = [
          "/etc/srv/prometheus-config/alerts.yml:/etc/prometheus/alerts.yml:ro"
        ];
      };

      # Native NixOS service keeps metrics collection lightweight.
      services.prometheus.exporters.node = {
        enable = true;
        port = nodeExporterPort;
        enabledCollectors = [
          "cpu"
          "cpufreq"
          "diskstats"
          "meminfo"
          "netdev"
          "netstat"
          "stat"
          "ethtool"
          "lnstat"
          "logind"
          "perf"
          "systemd"
          "hwmon"
          "thermal_zone"
        ];
      };
    }
    (mylib.dockerHelpers.mkDockerNetwork {
      inherit config;
      name = "monitoring";
    })
    (mylib.dockerHelpers.mkContainerNetworkDeps {
      name = "monitoring";
      containers = [
        "victoriametrics"
        "victorialogs"
        "vector"
        "cadvisor"
        "vmagent"
        "vmalert"
        "alertmanager"
        "alertmanager-ntfy-bridge"
        "ntfy"
      ];
    })
    {
      services.traefik.dynamicConfigOptions.http = lib.mkMerge [
        (mylib.traefikHelpers.mkTraefikRoute {
          name = "victoriametrics";
          domain = vmDomain;
          port = vmPort;
        })
        (mylib.traefikHelpers.mkTraefikRoute {
          name = "victorialogs";
          domain = vlDomain;
          port = vlPort;
        })
      ];
    }
  ]
