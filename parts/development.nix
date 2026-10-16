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
    semgrepPython = pkgs.python3.withPackages (p: [p.pyyaml]);
    semgrepPackage = import ../lib/semgrep.nix {inherit pkgs;};
    terminalTypes = import ../lib/opencode-terminal-types.nix {inherit pkgs;};
    quotaModule = import ../modules/home-manager/core/tmux {
      inherit pkgs;
      myvars = import ../vars {};
      config.xdg.cacheHome = "/unused-quota-test-cache";
      config.home.homeDirectory = "/unused-navigation-test-home";
    };
    quotaHelper = builtins.head quotaModule.home.packages;
    terminalTestProcess = pkgs.writeShellScript "opencode-terminal-test-process" ''
      printf 'test-process-%s\n' "$2"
    '';
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
    checks.pre-commit-check = preCommitCheck;
    checks.semgrep-local =
      pkgs.runCommand "semgrep-local-tests" {
        src = ../.;
        nativeBuildInputs = [semgrepPython pkgs.semgrep];
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        SEMGREP_LOCAL_BINARY = "${semgrepPackage}/bin/semgrep-local";
      } ''
        export HOME="$TMPDIR/home"
        export SEMGREP_SETTINGS_FILE="$TMPDIR/settings.yml"
        # stdenv seeds offline sentinel CA paths; initialize the native library locally.
        export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
        export NIX_SSL_CERT_FILE="$SSL_CERT_FILE"
        export SEMGREP_SEND_METRICS=off SEMGREP_ENABLE_VERSION_CHECK=0 CI=true
        export PYTHONDONTWRITEBYTECODE=1
        mkdir -p "$HOME"
        cd "$src"
        semgrep scan --test --config security/semgrep --strict --metrics=off \
          --disable-version-check --disable-nosem --no-rewrite-rule-ids security/semgrep
        python3 tests/semgrep-local-test.py
        touch "$out"
      '';
    checks.tailnet-policy =
      pkgs.runCommand "tailnet-policy-tests" {
        src = ../.;
        nativeBuildInputs = [pkgs.nodejs pkgs.bash pkgs.jq pkgs.coreutils pkgs.diffutils pkgs.shellcheck];
      } ''
        cd "$src"
        bash -n scripts/tailnet-policy.sh
        shellcheck scripts/tailnet-policy.sh
        node --test tests/tailnet-policy.test.mts
        touch "$out"
      '';
    checks.shupi-dns-routing = let
      host = inputs.self.nixosConfigurations.shupi.config;
      dns = host.services.adguardhome.settings.dns;
    in
      assert !host.services.unbound.enable;
      assert host.services.adguardhome.enable && dns.port == 53;
      assert dns.upstream_dns == ["10.64.0.1"] && dns.bootstrap_dns == ["10.64.0.1"];
      assert (dns.fallback_dns or []) == [];
      assert host.networking.nameservers == ["127.0.0.1"];
      assert host.virtualisation.docker.daemon.settings.dns == ["172.17.0.1"];
      assert !(builtins.elem 5335 host.networking.firewall.allowedTCPPorts);
      assert !(builtins.elem 5335 host.networking.firewall.allowedUDPPorts);
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
      assert builtins.length (builtins.attrNames aliases) == 23;
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
    checks.tmux-navigation =
      pkgs.runCommand "tmux-navigation-tests" {
        src = ../.;
        nativeBuildInputs = [pkgs.nodejs pkgs.tmux pkgs.fzf pkgs.typescript];
        TMUX_NAVIGATION_TEST_SHELL = pkgs.runtimeShell;
      } ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        tsc --project "$src/tests/tmux-navigation.tsconfig.json" --typeRoots ${terminalTypes}
        node --test "$src/tests/tmux-navigation.test.mts"
        touch "$out"
      '';
    checks.python-tests =
      pkgs.runCommand "python-tests" {
        src = ../.;
        nativeBuildInputs = [pkgs.python3];
      } ''
        export HOME="$TMPDIR/home"
        export PYTHONDONTWRITEBYTECODE=1
        mkdir -p "$HOME"
        cp -R "$src" source
        chmod -R u+w source
        cd source
        # Git snapshots omit the manifest's two excluded empty placeholders.
        mkdir -p modules/home-manager/core/opencode/config/skills/{dispatching-parallel-agents,impeccable-style}
        python3 tests/status-digest-test.py
        python3 tests/agent-browser-task-test.py
        python3 tests/agent-capabilities-test.py
        python3 tests/i-have-adhd-test.py
        touch "$out"
      '';
    checks.security-audit-validators =
      pkgs.runCommand "security-audit-validator-tests" {
        src = ../modules/home-manager/core/opencode/config/skills/security-audit;
        nativeBuildInputs = [pkgs.nodejs];
      } ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        node --test "$src/validate-findings.test.cjs" "$src/validate-coverage-ledger.test.cjs"
        touch "$out"
      '';
    checks.codex-quota =
      pkgs.runCommand "codex-quota-tests" {
        src = ../.;
        nativeBuildInputs = [pkgs.nodejs pkgs.tmux pkgs.typescript];
        CODEX_QUOTA_TEST_HELPER = "${quotaHelper}/bin/codex-quota";
        CODEX_QUOTA_TEST_CONFIG = pkgs.writeText "quota-tmux.conf" quotaModule.programs.tmux.extraConfig;
      } ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        tsc --project "$src/tests/codex-quota.tsconfig.json" --typeRoots ${terminalTypes}
        node --test "$src/tests/codex-quota.test.mts"
        touch "$out"
      '';
    checks.opencode-terminal =
      pkgs.runCommand "opencode-terminal-tests" {
        src = ../.;
        nativeBuildInputs = [pkgs.nodejs pkgs.tmux pkgs.typescript] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [pkgs.procps];
        OPENCODE_TERMINAL_PS =
          if pkgs.stdenv.isDarwin
          then "${terminalTestProcess}"
          else "${pkgs.procps}/bin/ps";
      } ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        tsc --project "$src/tests/opencode-terminal.tsconfig.json" --typeRoots ${terminalTypes}
        node --test "$src/tests/opencode-terminal.test.mts" "$src/tests/tmux-terminal.test.mts"
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
