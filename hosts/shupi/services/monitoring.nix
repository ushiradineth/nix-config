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
        image = "victoriametrics/victoria-metrics:latest";
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

      virtualisation.oci-containers.containers.cadvisor = {
        image = "gcr.io/cadvisor/cadvisor:latest";
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
          "-httpListenAddr=127.0.0.1:${toString vmagentPort}"
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
      config = config;
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
