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
  clientRedirectUris = lib.concatStringsSep "," [
    "http://127.0.0.1:60488/auth/google/callback"
    "http://127.0.0.1:60489/auth/google/callback"
    "http://127.0.0.1:19876/mcp/oauth/callback"
  ];
  gmailReadScopes = lib.concatStringsSep " " [
    "openid"
    "https://www.googleapis.com/auth/userinfo.email"
    "https://www.googleapis.com/auth/userinfo.profile"
    "https://www.googleapis.com/auth/gmail.readonly"
  ];
  environmentVersion = pkgs.writeText "google-mcp-environment-version" ''
    MCP_ENABLE_OAUTH21=true
    WORKSPACE_MCP_STATELESS_MODE=false
    WORKSPACE_MCP_MAX_FILE_BYTES=16777216
    WORKSPACE_MCP_OAUTH_PROXY_STORAGE_BACKEND=disk
    WORKSPACE_MCP_PERMISSIONS=${permissions}
    WORKSPACE_EXTERNAL_URL=https://${domain}
    GOOGLE_OAUTH_REDIRECT_URI=https://${domain}/oauth2callback
    WORKSPACE_MCP_ALLOWED_CLIENT_REDIRECT_URIS=${clientRedirectUris}
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
    image = "ghcr.io/ushiradineth/google-workspace-mcp:account-identity-73c2250f6b16@sha256:871b53e2ef00db337e9183b286b1e970c744ae98db36577df8f8c6f417319f90";
    autoStart = true;
    log-driver = "json-file";
    ports = ["127.0.0.1:${toString port}:8000"];
    volumes = [
      "${dataDir}:/data"
      "${clientSecret}:/run/secrets/google-oauth.json:ro"
    ];
    environment = {
      HOME = "/tmp";
      MCP_ENABLE_OAUTH21 = "true";
      WORKSPACE_MCP_STATELESS_MODE = "false";
      WORKSPACE_MCP_MAX_FILE_BYTES = "16777216";
      WORKSPACE_MCP_OAUTH_PROXY_STORAGE_BACKEND = "disk";
      WORKSPACE_MCP_OAUTH_PROXY_DISK_DIRECTORY = "/data/oauth-proxy";
      WORKSPACE_MCP_PERMISSIONS = permissions;
      WORKSPACE_MCP_HOST = "0.0.0.0";
      WORKSPACE_MCP_PORT = "8000";
      WORKSPACE_EXTERNAL_URL = "https://${domain}";
      GOOGLE_OAUTH_REDIRECT_URI = "https://${domain}/oauth2callback";
      GOOGLE_CLIENT_SECRET_PATH = "/run/secrets/google-oauth.json";
      WORKSPACE_MCP_ALLOWED_CLIENT_REDIRECT_URIS = clientRedirectUris;
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
    routers.google-mcp-gmail =
      route.routers.google-mcp
      // {
        rule = "${route.routers.google-mcp.rule} && Path(`/mcp`) && Header(`X-Workspace-MCP-Profile`, `gmail-readonly`)";
        middlewares = ["google-mcp-tailnet-only" "google-mcp-gmail-scopes"];
      };
    middlewares.google-mcp-gmail-scopes.headers.customResponseHeaders.WWW-Authenticate = ''Bearer scope="${gmailReadScopes}", resource_metadata="https://${domain}/.well-known/oauth-protected-resource/mcp"'';
  };
}
