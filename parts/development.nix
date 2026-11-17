{inputs, ...}: {
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem = {
    config,
    lib,
    pkgs,
    system,
    ...
  }: let
    nodeTypes = import ../lib/node-types.nix {inherit pkgs;};
    assistantChecks = import ../modules/home-manager/core/opencode/assistant/tests {inherit pkgs nodeTypes;};
    tmuxChecks = import ../modules/home-manager/core/tmux/tests {inherit pkgs nodeTypes;};
    preCommitCheck = inputs.pre-commit-hooks.lib.${system}.run {
      src = ../.;
      hooks = {
        alejandra.enable = true;
        prettier = {
          enable = true;
          package = pkgs.prettier;
          settings = {
            write = true;
            configPath = "./.prettierrc.yaml";
          };
        };
        deadnix.enable = true;
        statix.enable = true;
        typos = {
          enable = true;
          settings = {
            configPath = "./.typos.toml";
            write = true;
          };
        };
      };
    };
  in {
    imports = lib.optionals (system == "aarch64-darwin") [
      {
        checks.myx = import ../modules/nix-modules/darwin/myx/tests {inherit lib pkgs;};
        checks.myx-launcher = import ../modules/nix-modules/darwin/myx/tests/launcher.nix {inherit lib pkgs;};
      }
    ];

    checks.opencode-assistant = assistantChecks.assistant;
    checks.opencode-documents = assistantChecks.documents;
    checks.pre-commit-check = preCommitCheck;
    checks.neovim-workflow = import ../tests/neovim-workflow.nix {
      inherit pkgs;
      inherit (inputs) nixvim;
    };
    checks.semgrep-local = import ../modules/home-manager/core/semgrep/tests {inherit pkgs;};
    checks.tailnet-policy = import ../hosts/shupi/tailscale/tests {inherit pkgs;};
    checks.shupi-selfsync = import ../hosts/shupi/services/selfsync/tests.nix {
      inherit pkgs;
      host = inputs.self.nixosConfigurations.shupi.config;
    };
    checks.shupi-dns-routing = let
      checkMode = enabled: let
        host =
          (inputs.self.nixosConfigurations.shupi.extendModules {
            modules = [{services.mullvad-vpn.enable = lib.mkForce enabled;}];
          }).config;
        dns = host.services.adguardhome.settings.dns;
        challenge = host.services.traefik.staticConfigOptions.certificatesResolvers.letsencrypt.acme.dnsChallenge;
        tunnel = host.systemd.services.cloudflared-tunnel-shupi;
        resolvers =
          if enabled
          then ["10.64.0.1"]
          else ["1.1.1.1" "1.0.0.1"];
        vpnTables = ["mullvad-tailscale" "tailscale-exit-nat" "tailscale-prerouting-mark"];
      in
        assert lib.assertMsg (dns.upstream_dns == resolvers && dns.bootstrap_dns == resolvers) "shupi DNS must follow Mullvad enablement";
        assert !host.services.unbound.enable;
        assert host.services.adguardhome.enable && dns.port == 53;
        assert (dns.fallback_dns or []) == [];
        assert host.networking.nameservers == ["127.0.0.1"];
        assert host.virtualisation.docker.daemon.settings.dns == ["172.17.0.1"];
        assert !(builtins.elem 5335 host.networking.firewall.allowedTCPPorts);
        assert !(builtins.elem 5335 host.networking.firewall.allowedUDPPorts);
        assert challenge.resolvers == map (address: "${address}:53") resolvers;
        assert challenge.disablePropagationCheck == enabled;
        assert host.services.adguardhome.settings.filtering.filtering_enabled;
        assert host.services.adguardhome.settings.filtering.protection_enabled;
        assert host.services.tailscale.enable && host.services.tailscale.useRoutingFeatures == "both";
        assert builtins.elem "--advertise-exit-node" host.services.tailscale.extraUpFlags;
        assert builtins.elem "--accept-dns=false" host.services.tailscale.extraUpFlags;
        assert lib.all (name: builtins.hasAttr name host.networking.nftables.tables == enabled) vpnTables;
        assert (host.systemd.services ? mullvad-daemon) == enabled;
        assert (host.systemd.services ? tailscale-route-fix) == enabled;
        assert (host.age.secrets ? mullvad-account-id) == enabled;
        assert builtins.elem host.services.mullvad-vpn.package host.environment.systemPackages == enabled;
        assert builtins.elem "mullvad-daemon.service" tunnel.after == enabled;
        assert builtins.elem "mullvad-daemon.service" tunnel.wants == enabled;
        assert builtins.elem "mullvad-daemon.service" tunnel.partOf == enabled;
        assert (tunnel.environment ? TUNNEL_EDGE_BIND_ADDRESS) == enabled;
        assert tunnel.environment.TUNNEL_DNS_RESOLVER_ADDRS == "1.1.1.1:53,1.0.0.1:53";
        assert (
          if enabled
          then lib.hasInfix "mullvad split-tunnel add $MAINPID" tunnel.serviceConfig.ExecStartPost
          else (tunnel.serviceConfig.ExecStartPost or "") == ""
        );
        assert !enabled || lib.hasInfix "lockdown-mode set on" host.systemd.services.mullvad-daemon.postStart; true;
    in
      assert checkMode true;
      assert checkMode false;
        pkgs.runCommand "shupi-dns-routing" {} ''
          touch "$out"
        '';
    checks.shupi-adguard-admin = let
      host = inputs.self.nixosConfigurations.shupi.config;
      adguard = host.services.adguardhome;
      backend = host.services.traefik.dynamicConfigOptions.http.services.adguard.loadBalancer.servers;
    in
      assert adguard.host == "127.0.0.1" && !adguard.openFirewall;
      assert adguard.settings.http.address == "127.0.0.1:48005";
      assert adguard.settings.querylog.interval == "1d" && adguard.settings.statistics.interval == "1d";
      assert builtins.filter (rewrite: !lib.hasSuffix ".shu" rewrite.domain) adguard.settings.filtering.rewrites
      == [
        {
          domain = "*.shupi.ushira.com";
          answer = "100.74.32.50";
          enabled = false;
        }
      ];
      assert adguard.settings.dns.bind_hosts == ["0.0.0.0"] && adguard.settings.dns.port == 53;
      assert backend == [{url = "http://127.0.0.1:48005";}];
      assert !(builtins.elem 48005 host.networking.firewall.allowedTCPPorts);
      assert !(builtins.elem 53 host.networking.firewall.allowedTCPPorts);
      assert !(builtins.elem 53 host.networking.firewall.allowedUDPPorts);
      assert host.networking.firewall.extraInputRules
      == ''
        iifname "end0" ip saddr 192.168.1.0/24 tcp dport 53 accept
        iifname "end0" ip saddr 192.168.1.0/24 udp dport 53 accept
        iifname "docker0" tcp dport 53 accept
        iifname "docker0" udp dport 53 accept
        iifname "br-*" tcp dport 53 accept
        iifname "br-*" udp dport 53 accept
      '';
      assert builtins.elem "tailscale0" host.networking.firewall.trustedInterfaces;
        pkgs.runCommand "shupi-adguard-admin" {} ''
          touch "$out"
        '';
    checks.shupi-short-urls = let
      host = inputs.self.nixosConfigurations.shupi.config;
      http = host.services.traefik.dynamicConfigOptions.http;
      rewrites = host.services.adguardhome.settings.filtering.rewrites;
      domains = lib.filterAttrs (name: domain: name != "EMAIL_DOMAIN" && lib.hasSuffix "_DOMAIN" name && (domain == "shupi.ushira.com" || lib.hasSuffix ".shupi.ushira.com" domain)) host.environment.variables;
      aliases = lib.mapAttrs' (_: domain:
        lib.nameValuePair (
          if domain == "shupi.ushira.com"
          then "home"
          else lib.removeSuffix ".shupi.ushira.com" domain
        )
        domain)
      domains;
      routers = lib.filterAttrs (name: _: lib.hasPrefix "short-url-" name) http.routers;
      middlewares = lib.filterAttrs (name: _: lib.hasPrefix "short-url-" name) http.middlewares;
      configuration = pkgs.writeText "traefik-short-urls-test.yaml" (builtins.toJSON {
        entryPoints = {
          web = host.services.traefik.staticConfigOptions.entryPoints.web // {address = "127.0.0.1:18080";};
          websecure.address = "127.0.0.1:18443";
        };
        providers.file.filename = pkgs.writeText "traefik-short-urls-dynamic.yaml" (builtins.toJSON {http = {inherit routers middlewares;};});
        providers.file.watch = false;
      });
    in
      assert builtins.length (builtins.attrNames aliases) == 22;
      assert builtins.length (builtins.attrNames routers) == builtins.length (builtins.attrNames aliases);
      assert lib.all (alias:
        builtins.elem {
          domain = "${alias}.shu";
          answer = "100.74.32.50";
          enabled = true;
        }
        rewrites) (builtins.attrNames aliases);
      assert lib.all (router: router.entryPoints == ["web"] && !(router ? tls) && router.priority > host.services.traefik.staticConfigOptions.entryPoints.web.http.redirections.entryPoint.priority) (builtins.attrValues routers);
        pkgs.runCommand "shupi-short-urls" {
          nativeBuildInputs = [pkgs.traefik pkgs.curl];
        } ''
          traefik --configFile=${configuration} > traefik.log 2>&1 &
          pid=$!
          trap 'kill "$pid"; wait "$pid" || true' EXIT
          ready=0
          for attempt in $(seq 1 100); do
            if [ "$(curl --silent --noproxy '*' --max-time 1 -H 'Host: home.shu' \
              -o /dev/null -w '%{redirect_url}' http://127.0.0.1:18080/)" = 'https://shupi.ushira.com/' ]; then
              ready=1
              break
            fi
            sleep 0.1
          done
          if [ "$ready" != 1 ]; then
            cat traefik.log
            exit 1
          fi
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (alias: domain: ''
              curl --silent --show-error --noproxy '*' --max-time 5 \
                -H 'Host: ${alias}.shu:18080' -D headers -o /dev/null \
                'http://127.0.0.1:18080/folder/file?download=1&next=%2F'
              tr -d '\r' < headers > normalized
              grep -Fx 'HTTP/1.1 302 Found' normalized || { cat normalized traefik.log; exit 1; }
              grep -Fx 'Location: https://${domain}/folder/file?download=1&next=%2F' normalized || { cat normalized traefik.log; exit 1; }
            '')
            aliases)}
          curl --silent --show-error --noproxy '*' --max-time 5 \
            -H 'Host: sf.shupi.ushira.com' -D headers -o /dev/null http://127.0.0.1:18080/
          tr -d '\r' < headers > normalized
          grep -Fx 'Location: https://sf.shupi.ushira.com:18443/' normalized
          touch "$out"
        '';
    checks.shupi-shu-ssh-route = let
      generatedConfig = inputs.self.nixosConfigurations.shupi.config.programs.ssh.extraConfig;
    in
      pkgs.runCommand "shupi-shu-ssh-route" {
        nativeBuildInputs = [pkgs.openssh pkgs.gawk];
        configFile = pkgs.writeText "shupi-ssh-route.conf" generatedConfig;
      } ''
        ssh -G -F "$configFile" shu > effective.conf
        awk 'tolower($1) == "hostname" { host = $2 } END { exit !(host == "100.120.236.115") }' effective.conf
        touch "$out"
      '';
    checks.shu-ssh-authentication = let
      generatedConfig = inputs.self.darwinConfigurations.shu.config.environment.etc."ssh/sshd_config.d/100-nix-darwin.conf".source.drvAttrs.text;
    in
      pkgs.runCommand "shu-ssh-authentication" {
        nativeBuildInputs = [pkgs.openssh pkgs.gawk];
        configFile = pkgs.writeText "shu-ssh-candidate.conf" generatedConfig;
      } ''
        sshd -G -f "$configFile" > effective.conf
        awk '
          tolower($1) == "passwordauthentication" { password = $2 }
          tolower($1) == "kbdinteractiveauthentication" { keyboard = $2 }
          tolower($1) == "pubkeyauthentication" { key = $2 }
          tolower($1) == "allowtcpforwarding" { tcp = $2 }
          tolower($1) == "allowagentforwarding" { agent = $2 }
          END { exit !(password == "no" && keyboard == "no" && key == "yes" && tcp == "yes" && agent == "yes") }
        ' effective.conf
        touch "$out"
      '';
    checks.tmux-navigation = tmuxChecks.navigation;
    checks.agent-guidance = import ../tests/agent-guidance.nix {inherit lib pkgs;};
    checks.google-mcp = import ../tests/google-mcp.nix {
      inherit lib pkgs;
      host = inputs.self.nixosConfigurations.shupi.config;
    };
    checks.ntfy-log-digest = import ../hosts/shupi/services/ntfy-log-digest/tests {inherit pkgs;};
    checks.security-audit-validators =
      pkgs.runCommand "security-audit-validator-tests" {
        src = ../modules/home-manager/core/opencode/config/skills/security-audit;
        nativeBuildInputs = [pkgs.nodejs pkgs.typescript];
      } ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        tsc --project "$src/tests.tsconfig.json" --typeRoots ${nodeTypes}
        node --test "$src/validate-findings.test.mts" "$src/validate-coverage-ledger.test.mts"
        touch "$out"
      '';
    checks.codex-quota = tmuxChecks.quota;
    checks.opencode-terminal = import ../modules/home-manager/core/opencode/terminal/tests {inherit pkgs nodeTypes;};
    checks.opencode-workflow =
      pkgs.runCommand "opencode-workflow-tests" {
        src = ../.;
        nativeBuildInputs = [pkgs.nodejs pkgs.git pkgs.ripgrep pkgs.typescript];
        OPENCODE_TEST_BINARY = "${import ../modules/home-manager/core/opencode/package.nix {
          inherit pkgs;
          upstream = inputs.llm-agents.packages.${system}.opencode2;
        }}/bin/opencode";
      } ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        tsc --project "$src/tests/opencode-workflow.tsconfig.json" --typeRoots ${nodeTypes}
        node --test "$src/tests/opencode-workflow.test.mts"
        touch "$out"
      '';

    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        alejandra.enable = true;
        prettier = {
          enable = true;
          package = pkgs.prettier;
          includes = [
            "*.json"
            "*.js"
            "*.mjs"
            "*.ts"
            "*.mts"
            "*.md"
            "*.yaml"
            "*.yml"
            "*.css"
          ];
          excludes = [
            "flake.lock"
          ];
        };
        shfmt = {
          enable = true;
          indent_size = 2;
        };
        shellcheck = {
          enable = true;
          excludes = [
            ".envrc"
          ];
        };
        deadnix.enable = true;
        statix.enable = true;
        typos = {
          enable = true;
          configFile = ".typos.toml";
        };
      };
    };

    formatter = config.treefmt.build.wrapper;

    devShells.default = pkgs.mkShell {
      name = "nix-config-devshell";
      packages = with pkgs; [
        deadnix
        statix
        nil
        nixos-rebuild
        home-manager
        git
        jq
        convco
        config.treefmt.build.wrapper
      ];
      NIX_CONFIG = "experimental-features = nix-command flakes";
      inherit (preCommitCheck) shellHook;
    };
  };
}
