{
  lib,
  pkgs,
  host,
}: let
  http = host.services.traefik.dynamicConfigOptions.http;
  domain = host.environment.variables.GOOGLE_MCP_DOMAIN;
  opencode = builtins.fromJSON (builtins.readFile ../modules/home-manager/core/opencode/config/opencode.json);
  profileHeaders = lib.concatStringsSep " " (lib.mapAttrsToList (name: value: "-H ${lib.escapeShellArg "${name}: ${value}"}") opencode.mcp.google.headers);
  expectedChallenge = ''Bearer scope="${opencode.mcp.google.oauth.scope}", resource_metadata="${lib.removeSuffix "/mcp" opencode.mcp.google.url}/.well-known/oauth-protected-resource/mcp"'';
  routers = lib.mapAttrs (_: router:
    (builtins.removeAttrs router ["tls" "entrypoints"])
    // {entryPoints = ["web"];}) {
    inherit (http.routers) google-mcp google-mcp-gmail;
  };
  backend = pkgs.writeShellScript "google-mcp-fixture" ''
    printf 'HTTP/1.1 401 Unauthorized\r\nWWW-Authenticate: Bearer scope="fixture-broad"\r\nContent-Length: 0\r\nConnection: close\r\n\r\n'
  '';
  configuration = pkgs.writeText "google-mcp-traefik-test.json" (builtins.toJSON {
    entryPoints.web.address = "127.0.0.1:18082";
    providers.file.filename = pkgs.writeText "google-mcp-routes-test.json" (builtins.toJSON {
      http = {
        inherit routers;
        services.google-mcp.loadBalancer.servers = [{url = "http://127.0.0.1:18083";}];
        middlewares = {
          inherit (http.middlewares) google-mcp-gmail-scopes;
          google-mcp-tailnet-only.ipAllowList.sourceRange = ["127.0.0.1/32"];
        };
      };
    });
    providers.file.watch = false;
  });
in
  assert lib.all (router: builtins.elem "google-mcp-tailnet-only" router.middlewares) (builtins.attrValues routers);
  assert lib.all (uri: builtins.elem uri (lib.splitString "," host.virtualisation.oci-containers.containers.google-mcp.environment.WORKSPACE_MCP_ALLOWED_CLIENT_REDIRECT_URIS)) [
    "http://127.0.0.1:60488/auth/google/callback"
    "http://127.0.0.1:60489/auth/google/callback"
    "http://127.0.0.1:19876/mcp/oauth/callback"
  ];
    pkgs.runCommand "google-mcp-routing-tests" {
      nativeBuildInputs = [pkgs.traefik pkgs.curl pkgs.socat];
    } ''
      socat TCP4-LISTEN:18083,bind=127.0.0.1,reuseaddr,fork EXEC:${backend} > backend.log 2>&1 &
      backend_pid=$!
      traefik --configFile=${configuration} > traefik.log 2>&1 &
      proxy_pid=$!
      trap 'kill "$proxy_pid" "$backend_pid"; wait || true' EXIT
      ready=0
      for attempt in $(seq 1 100); do
        if [ "$(curl --silent --noproxy '*' --max-time 1 -H 'Host: ${domain}' -o /dev/null -w '%{http_code}' http://127.0.0.1:18082/mcp)" = 401 ]; then
          ready=1
          break
        fi
        sleep 0.1
      done
      if [ "$ready" != 1 ]; then
        cat traefik.log backend.log
        exit 1
      fi
      challenge() {
        curl --silent --show-error --noproxy '*' --max-time 5 -H 'Host: ${domain}' "$@" \
          -D headers -o /dev/null http://127.0.0.1:18082/mcp
        grep -F '401 Unauthorized' headers > /dev/null || return 1
        awk 'tolower($1) == "www-authenticate:" { sub(/\r$/, ""); $1=""; sub(/^ /, ""); print }' headers
      }
      [ "$(challenge)" = 'Bearer scope="fixture-broad"' ]
      [ "$(challenge -H 'X-Workspace-MCP-Profile: other')" = 'Bearer scope="fixture-broad"' ]
      [ "$(challenge ${profileHeaders})" = ${lib.escapeShellArg expectedChallenge} ]
      touch "$out"
    ''
