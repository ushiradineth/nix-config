{
  config,
  hostname,
  lib,
  mylib,
  mysecrets,
  pkgs,
  ...
}: let
  port = config.ports.googleMcp;
  domain = config.environment.variables.GOOGLE_MCP_DOMAIN;
  runtimeDir = "/run/google-mcp";
  clientSecret = "${runtimeDir}/client-secret.json";
  dataDir = "/srv/google-mcp";
  permissions = "gmail:send calendar:full drive:full docs:full sheets:full";
  environmentVersion = pkgs.writeText "google-mcp-environment-version" ''
    MCP_ENABLE_OAUTH21=true
    WORKSPACE_MCP_STATELESS_MODE=true
    WORKSPACE_MCP_OAUTH_PROXY_STORAGE_BACKEND=disk
    WORKSPACE_MCP_PERMISSIONS=${permissions}
    WORKSPACE_EXTERNAL_URL=https://${domain}
    GOOGLE_OAUTH_REDIRECT_URI=https://${domain}/oauth2callback
    WORKSPACE_MCP_ALLOWED_CLIENT_REDIRECT_URIS=https://${config.environment.variables.PAPERCLIP_DOMAIN}/api/tools/oauth/callback
  '';
  route = mylib.traefikHelpers.mkTraefikRoute {
    name = "google-mcp";
    host = "127.0.0.1";
    inherit domain port;
  };
in {
  age.secrets.google-mcp-oauth = {
    file = "${mysecrets}/${hostname}/google-mcp-oauth.age";
    mode = "0400";
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0700 1000 1000 -"
    "d ${dataDir}/oauth-proxy 0700 1000 1000 -"
  ];

  systemd.services.google-mcp-secrets = {
    description = "Prepare Google MCP OAuth client credentials";
    before = ["docker-google-mcp.service"];
    requiredBy = ["docker-google-mcp.service"];
    restartTriggers = [config.age.secrets.google-mcp-oauth.file];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      UMask = "0077";
    };
    script = ''
      set -euo pipefail
      ${pkgs.coreutils}/bin/install -d -m 0700 -o 1000 -g 1000 ${runtimeDir}
      ${pkgs.coreutils}/bin/install -m 0400 -o 1000 -g 1000 \
        ${config.age.secrets.google-mcp-oauth.path} ${clientSecret}
    '';
  };

  virtualisation.oci-containers.containers.google-mcp = {
    image = "ghcr.io/taylorwilsdon/google_workspace_mcp:sha-2e9e9e7@sha256:52ce59e89e0dbc45725e78b6600c37dfacd529480a35f784eb483582f0f61512";
    autoStart = true;
    log-driver = "json-file";
    ports = ["127.0.0.1:${toString port}:8000"];
    volumes = [
      "${dataDir}:/data"
      "${clientSecret}:/run/secrets/google-oauth.json:ro"
    ];
    environment = {
      MCP_ENABLE_OAUTH21 = "true";
      WORKSPACE_MCP_STATELESS_MODE = "true";
      WORKSPACE_MCP_OAUTH_PROXY_STORAGE_BACKEND = "disk";
      WORKSPACE_MCP_OAUTH_PROXY_DISK_DIRECTORY = "/data/oauth-proxy";
      WORKSPACE_MCP_PERMISSIONS = permissions;
      WORKSPACE_MCP_HOST = "0.0.0.0";
      WORKSPACE_MCP_PORT = "8000";
      WORKSPACE_EXTERNAL_URL = "https://${domain}";
      GOOGLE_OAUTH_REDIRECT_URI = "https://${domain}/oauth2callback";
      GOOGLE_CLIENT_SECRET_PATH = "/run/secrets/google-oauth.json";
      WORKSPACE_MCP_ALLOWED_CLIENT_REDIRECT_URIS = "https://${config.environment.variables.PAPERCLIP_DOMAIN}/api/tools/oauth/callback";
      WORKSPACE_MCP_DISABLE_LOCAL_FILES = "true";
      WORKSPACE_MCP_BRAND_NAME = "Shu Google MCP";
      PYTHONDONTWRITEBYTECODE = "1";
    };
    extraOptions = [
      "--cpus=1"
      "--memory=512m"
      "--memory-swap=512m"
      "--pids-limit=256"
      "--cap-drop=ALL"
      "--security-opt=no-new-privileges:true"
      "--read-only"
      "--tmpfs=/tmp:rw,noexec,nosuid,size=64m"
      "--health-cmd=curl -fsS --max-time 5 http://127.0.0.1:8000/health"
      "--health-interval=30s"
      "--health-timeout=10s"
      "--health-retries=5"
      "--health-start-period=60s"
      "--log-opt=max-size=10m"
      "--log-opt=max-file=3"
    ];
  };

  systemd.services.docker-google-mcp.restartTriggers = [
    config.age.secrets.google-mcp-oauth.file
    environmentVersion
  ];

  services.traefik.dynamicConfigOptions.http = lib.recursiveUpdate route {
    middlewares.google-mcp-tailnet-only.ipAllowList.sourceRange = [
      "100.64.0.0/10"
      "fd7a:115c:a1e0::/48"
      "172.17.0.0/16"
    ];
    routers.google-mcp.middlewares = ["google-mcp-tailnet-only"];
  };
}
