{config, ...}: {
  services.prometheus = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = config.ports.prometheus;

    exporters = {
      node = {
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
        ];
      };
    };

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = ["0.0.0.0:${toString config.services.prometheus.exporters.node.port}"];
          }
        ];
      }
    ];
  };
}
