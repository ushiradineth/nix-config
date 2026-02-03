{
  config,
  pkgs,
  mylib,
  lib,
  ...
}: let
  port = config.ports.alertmanager;
  bridgePort = config.ports.alertmanager-ntfy;
  domain = config.environment.variables.ALERTMANAGER_DOMAIN;
  ntfyDomain = config.environment.variables.NTFY_DOMAIN;

  # Bridge script that converts AlertManager webhooks to ntfy format
  alertmanagerNtfyBridge = pkgs.writeScript "alertmanager-ntfy-bridge" ''
    #!${pkgs.python3}/bin/python3
    import json
    import http.server
    import urllib.request
    import urllib.error
    import base64
    import os
    import sys

    NTFY_URL = os.environ.get("NTFY_URL", "https://${ntfyDomain}/alerts")
    NTFY_USER = os.environ.get("NTFY_USER", "")
    NTFY_PASS = os.environ.get("NTFY_PASS", "")

    class AlertHandler(http.server.BaseHTTPRequestHandler):
        def do_POST(self):
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length)

            try:
                data = json.loads(body)
                self.process_alerts(data)
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b'OK')
            except Exception as e:
                print(f"Error: {e}", file=sys.stderr)
                self.send_response(500)
                self.end_headers()
                self.wfile.write(str(e).encode())

        def process_alerts(self, data):
            for alert in data.get("alerts", []):
                status = alert.get("status", "unknown")
                labels = alert.get("labels", {})
                annotations = alert.get("annotations", {})

                alertname = labels.get("alertname", "Unknown Alert")
                severity = labels.get("severity", "warning")
                instance = labels.get("instance", "unknown")

                summary = annotations.get("summary", alertname)
                description = annotations.get("description", "No description")

                # Map severity to ntfy priority
                priority_map = {"critical": "urgent", "warning": "high", "info": "default"}
                priority = priority_map.get(severity, "default")

                # Simple text tags
                tag = f"{status},{severity}"

                # Build message
                title = f"[{status.upper()}] {summary}"
                message = f"{description}\n\nInstance: {instance}\nSeverity: {severity}"

                self.send_to_ntfy(title, message, priority, tag)

        def send_to_ntfy(self, title, message, priority, tag):
            headers = {
                "Title": title,
                "Priority": priority,
                "Tags": tag,
                "Content-Type": "text/plain",
            }

            if NTFY_USER and NTFY_PASS:
                auth = base64.b64encode(f"{NTFY_USER}:{NTFY_PASS}".encode()).decode()
                headers["Authorization"] = f"Basic {auth}"

            req = urllib.request.Request(NTFY_URL, data=message.encode(), headers=headers)
            try:
                with urllib.request.urlopen(req) as resp:
                    print(f"Sent to ntfy: {title} -> {resp.status}")
            except urllib.error.URLError as e:
                print(f"Failed to send to ntfy: {e}", file=sys.stderr)

        def log_message(self, format, *args):
            print(f"[alertmanager-ntfy] {args[0]}", file=sys.stderr)

    if __name__ == "__main__":
        server = http.server.HTTPServer(("127.0.0.1", ${toString bridgePort}), AlertHandler)
        print(f"AlertManager-ntfy bridge listening on 127.0.0.1:${toString bridgePort}")
        server.serve_forever()
  '';
in {
  # Storage directory
  systemd.tmpfiles.rules = [
    "d /srv/alertmanager 0755 root root -"
  ];

  # Alertmanager container (uses host network to reach bridge service)
  virtualisation.oci-containers.containers.alertmanager = {
    image = "prom/alertmanager:latest";
    autoStart = true;
    extraOptions = ["--network=host"];
    volumes = [
      "/srv/alertmanager:/alertmanager"
      "/srv/alertmanager/config.yml:/etc/alertmanager/config.yml:ro"
    ];
    cmd = [
      "--config.file=/etc/alertmanager/config.yml"
      "--storage.path=/alertmanager"
      "--web.external-url=https://${domain}"
      "--web.listen-address=127.0.0.1:${toString port}"
    ];
  };

  # Create bridge environment file during activation (before services start)
  # Uses localhost HTTP to avoid SSL cert issues (ntfy container on same host)
  system.activationScripts.alertmanagerNtfyBridgeEnv = ''
    mkdir -p /var/lib/alertmanager-ntfy
    NTFY_AUTH=$(cat ${config.age.secrets.ntfy-credentials.path} | tr -d '[:space:]')
    NTFY_USER=''${NTFY_AUTH%%:*}
    NTFY_PASS=''${NTFY_AUTH#*:}
    cat > /var/lib/alertmanager-ntfy/env <<'ENVEOF'
NTFY_URL=http://127.0.0.1:${toString config.ports.ntfy}/alerts
ENVEOF
    echo "NTFY_USER=$NTFY_USER" >> /var/lib/alertmanager-ntfy/env
    echo "NTFY_PASS=$NTFY_PASS" >> /var/lib/alertmanager-ntfy/env
    chmod 600 /var/lib/alertmanager-ntfy/env
  '';

  # Bridge service that converts AlertManager webhooks to ntfy format
  systemd.services.alertmanager-ntfy-bridge = {
    description = "AlertManager to ntfy bridge";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];

    serviceConfig = {
      Type = "simple";
      ExecStart = alertmanagerNtfyBridge;
      Restart = "always";
      RestartSec = "5s";
      EnvironmentFile = "/var/lib/alertmanager-ntfy/env";
    };
  };

  # Create alertmanager configuration (now points to local bridge)
  system.activationScripts.alertmanagerConfig = ''
    mkdir -p /srv/alertmanager
    cat > /srv/alertmanager/config.yml <<EOF
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  receiver: 'ntfy-bridge'

receivers:
  - name: 'ntfy-bridge'
    webhook_configs:
      - url: 'http://127.0.0.1:${toString bridgePort}/'
        send_resolved: true

inhibit_rules:
  # Inhibit warnings if critical alert is firing
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']
EOF
    chmod 644 /srv/alertmanager/config.yml
  '';

  # Traefik route
  services.traefik.dynamicConfigOptions.http = mylib.traefikHelpers.mkTraefikRoute {
    name = "alertmanager";
    domain = domain;
    port = port;
  };
}
