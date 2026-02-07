{
  config,
  mylib,
  mysecrets,
  hostname,
  ...
}: let
  port = config.ports.alertmanager;
  domain = config.environment.variables.ALERTMANAGER_DOMAIN;

  # Bridge script that converts AlertManager webhooks to ntfy format
  bridgeScript = ''
    #!/usr/bin/env python3
    import json
    import http.server
    import urllib.request
    import urllib.error
    import base64
    import os
    import sys

    NTFY_URL = os.environ.get("NTFY_URL", "http://ntfy/alerts")
    NTFY_USER = os.environ.get("NTFY_USER", "")
    NTFY_PASS = os.environ.get("NTFY_PASS", "")

    def strip_non_ascii(s):
        """Remove non-ASCII characters from string for HTTP headers."""
        return s.encode('ascii', 'ignore').decode('ascii')

    class AlertHandler(http.server.BaseHTTPRequestHandler):
        def do_POST(self):
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length)

            try:
                body_str = body.decode('utf-8')
                data = json.loads(body_str)
                self.process_alerts(data)
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b'OK')
            except json.JSONDecodeError as e:
                print(f"JSON Error: {e}", file=sys.stderr)
                print(f"Raw body: {body[:500]}", file=sys.stderr)
                self.send_response(500)
                self.end_headers()
                self.wfile.write(str(e).encode())
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

                priority_map = {"critical": "urgent", "warning": "high", "info": "default"}
                priority = priority_map.get(severity, "default")

                tag = f"{status},{severity}"
                title = f"[{status.upper()}] {summary}"
                message = f"{description}\n\nInstance: {instance}\nSeverity: {severity}"

                self.send_to_ntfy(title, message, priority, tag)

        def send_to_ntfy(self, title, message, priority, tag):
            headers = {
                "Title": strip_non_ascii(title),
                "Priority": priority,
                "Tags": strip_non_ascii(tag),
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
        server = http.server.HTTPServer(("0.0.0.0", 8080), AlertHandler)
        print("AlertManager-ntfy bridge listening on 0.0.0.0:8080")
        server.serve_forever()
  '';
in {
  age.secrets.ntfy-alertmanager-credentials = {
    file = "${mysecrets}/${hostname}/ntfy-credentials.age";
    mode = "0400";
  };

  # Storage directories
  systemd.tmpfiles.rules = [
    "d /srv/alertmanager 0755 65534 65534 -"
    "d /srv/alertmanager-ntfy-bridge 0755 root root -"
  ];

  # Create bridge script and env file
  system.activationScripts.alertmanagerNtfyBridgeScript = ''
        mkdir -p /srv/alertmanager-ntfy-bridge
        cat > /srv/alertmanager-ntfy-bridge/bridge.py <<'SCRIPT'
    ${bridgeScript}
    SCRIPT
        chmod 755 /srv/alertmanager-ntfy-bridge/bridge.py

        # Create env file from credentials (user:pass format)
        NTFY_AUTH=$(cat ${config.age.secrets.ntfy-alertmanager-credentials.path} | tr -d '[:space:]')
        NTFY_USER=''${NTFY_AUTH%%:*}
        NTFY_PASS=''${NTFY_AUTH#*:}
        cat > /srv/alertmanager-ntfy-bridge/env <<EOF
    NTFY_USER=$NTFY_USER
    NTFY_PASS=$NTFY_PASS
    EOF
        chmod 600 /srv/alertmanager-ntfy-bridge/env
  '';

  # Alertmanager container
  virtualisation.oci-containers.containers.alertmanager = {
    image = "prom/alertmanager:latest";
    autoStart = true;
    ports = ["127.0.0.1:${toString port}:9093"];
    extraOptions = [
      "--network=monitoring"
      "--health-cmd=wget -qO- http://localhost:9093/-/healthy || exit 1"
      "--health-interval=30s"
      "--health-timeout=10s"
      "--health-retries=5"
      "--health-start-period=10s"
    ];
    volumes = [
      "/srv/alertmanager:/alertmanager"
      "/srv/alertmanager/config.yml:/etc/alertmanager/config.yml:ro"
    ];
    cmd = [
      "--config.file=/etc/alertmanager/config.yml"
      "--storage.path=/alertmanager"
      "--web.external-url=https://${domain}"
      "--web.listen-address=0.0.0.0:9093"
    ];
  };

  # Bridge container on monitoring network
  virtualisation.oci-containers.containers.alertmanager-ntfy-bridge = {
    image = "python:3.12-alpine";
    autoStart = true;
    extraOptions = ["--network=monitoring"];
    volumes = [
      "/srv/alertmanager-ntfy-bridge/bridge.py:/app/bridge.py:ro"
      "/srv/alertmanager-ntfy-bridge/env:/app/env:ro"
    ];
    environment = {
      NTFY_URL = "http://ntfy:80/alerts";
    };
    entrypoint = "/bin/sh";
    cmd = ["-c" "export $(cat /app/env | xargs) && python3 /app/bridge.py"];
  };

  # Create alertmanager configuration
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
          - url: 'http://alertmanager-ntfy-bridge:8080/'
            send_resolved: true

    inhibit_rules:
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
