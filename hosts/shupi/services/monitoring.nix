{
  config,
  lib,
  mylib,
  ...
}: let
  vmPort = config.ports.victoriametrics;
  vlPort = config.ports.victorialogs;
  vmDomain = config.environment.variables.VICTORIAMETRICS_DOMAIN;
  vlDomain = config.environment.variables.VICTORIALOGS_DOMAIN;
in
  lib.mkMerge [
    {
      virtualisation.oci-containers.containers.victoriametrics = {
        image = "victoriametrics/victoria-metrics:latest";
        autoStart = true;
        ports = ["127.0.0.1:${toString vmPort}:8428"];
        extraOptions = ["--network=monitoring"];
        cmd = [
          "-storageDataPath=/victoria-metrics-data"
          "-retentionPeriod=12"
        ];
        volumes = [
          "/srv/victoriametrics:/victoria-metrics-data"
        ];
      };

      virtualisation.oci-containers.containers.victorialogs = {
        image = "victoriametrics/victoria-logs:latest";
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
        image = "timberio/vector:latest-alpine";
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

      environment.etc."srv/prometheus-config/prometheus.yml".text = ''
        global:
          scrape_interval: 15s

        scrape_configs:
          - job_name: 'node'
            static_configs:
              - targets: ['127.0.0.1:9100']
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
                expr: 100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100) > 80
                for: 5m
                labels:
                  severity: warning
                annotations:
                  summary: "Low disk space on {{ $labels.instance }}"
                  description: "Disk usage is above 80% (current value: {{ $value | humanize }}%)"

              # Critical disk space
              - alert: CriticalDiskSpace
                expr: 100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100) > 90
                for: 2m
                labels:
                  severity: critical
                annotations:
                  summary: "Critical disk space on {{ $labels.instance }}"
                  description: "Disk usage is above 90% (current value: {{ $value | humanize }}%)"

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
        image = "victoriametrics/vmagent:latest";
        autoStart = true;
        extraOptions = [
          "--network=host"
        ];
        cmd = [
          "-promscrape.config=/etc/prometheus/prometheus.yml"
          "-remoteWrite.url=http://127.0.0.1:${toString vmPort}/api/v1/write"
        ];
        volumes = [
          "/srv/vmagent:/vmagent-data"
          "/etc/srv/prometheus-config/prometheus.yml:/etc/prometheus/prometheus.yml:ro"
        ];
      };

      # vmalert for processing alert rules
      virtualisation.oci-containers.containers.vmalert = {
        image = "victoriametrics/vmalert:latest";
        autoStart = true;
        extraOptions = [
          "--network=host"
        ];
        cmd = [
          "-datasource.url=http://127.0.0.1:${toString vmPort}"
          "-notifier.url=http://127.0.0.1:${toString config.ports.alertmanager}"
          "-remoteWrite.url=http://127.0.0.1:${toString vmPort}"
          "-remoteRead.url=http://127.0.0.1:${toString vmPort}"
          "-rule=/etc/prometheus/alerts.yml"
          "-external.url=https://${vmDomain}"
          "-evaluationInterval=1m"
        ];
        volumes = [
          "/etc/srv/prometheus-config/alerts.yml:/etc/prometheus/alerts.yml:ro"
        ];
      };

      # Native NixOS service keeps metrics collection lightweight.
      services.prometheus.exporters.node = {
        enable = true;
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
      config = config;
      name = "monitoring";
    })
    (mylib.dockerHelpers.mkContainerNetworkDeps {
      name = "monitoring";
      containers = [
        "victoriametrics"
        "victorialogs"
        "vector"
        "vmagent"
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
