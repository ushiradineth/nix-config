{
  config,
  pkgs,
  lib,
  mylib,
  myvars,
  hostname,
  mysecrets,
  ...
}: let
  port = config.ports.forgejo;
  domain = config.environment.variables.FORGEJO_DOMAIN;
  emailDomain = config.environment.variables.EMAIL_DOMAIN;
  smtpHost = config.environment.variables.SMTP_HOST;
  smtpPort = config.environment.variables.SMTP_PORT;
  smtpUser = config.environment.variables.SMTP_USER;
  adminUsername = "ushiradineth";
in
  lib.mkMerge [
    {
      # Age secrets for Forgejo
      age.secrets.forgejo-db-password = {
        file = "${mysecrets}/${hostname}/forgejo-db-password.age";
        mode = "0400";
      };

      age.secrets.forgejo-admin-password = {
        file = "${mysecrets}/${hostname}/forgejo-admin-password.age";
        mode = "0400";
      };

      age.secrets.forgejo-secret-key = {
        file = "${mysecrets}/${hostname}/forgejo-secret-key.age";
        mode = "0400";
      };

      age.secrets.github-token = {
        file = "${mysecrets}/${hostname}/github-token.age";
        mode = "0400";
      };

      age.secrets.resend-api-key = {
        file = "${mysecrets}/${hostname}/resend-api-key.age";
        mode = "0400";
      };

      # Create environment files and directories
      system.activationScripts.forgejo-env = ''
        mkdir -p /var/lib/forgejo
        mkdir -p /srv/forgejo/{data,repos,git}
        mkdir -p /srv/forgejo/git/.ssh
        chown -R 1000:1000 /srv/forgejo/{data,repos,git}

        DB_PASSWORD=$(cat ${config.age.secrets.forgejo-db-password.path})
        SECRET_KEY=$(cat ${config.age.secrets.forgejo-secret-key.path})
        SMTP_PASSWORD=$(cat ${config.age.secrets.resend-api-key.path} | tr -d '[:space:]')

        # PostgreSQL environment
        cat > /var/lib/forgejo/db.env << EOF
        POSTGRES_DB=forgejo
        POSTGRES_USER=forgejo
        POSTGRES_PASSWORD=$DB_PASSWORD
        EOF
        chmod 600 /var/lib/forgejo/db.env

        # Forgejo environment
        cat > /var/lib/forgejo/forgejo.env << EOF
        # Application
        FORGEJO__server__DOMAIN=${domain}
        FORGEJO__server__ROOT_URL=https://${domain}/
        FORGEJO__server__HTTP_PORT=3000
        FORGEJO__server__PROTOCOL=http

        # Database
        FORGEJO__database__DB_TYPE=postgres
        FORGEJO__database__HOST=forgejo-db:5432
        FORGEJO__database__NAME=forgejo
        FORGEJO__database__USER=forgejo
        FORGEJO__database__PASSWD=$DB_PASSWORD

        # Repository
        FORGEJO__repository__ROOT=/data/git/repositories
        FORGEJO__repository__DEFAULT_BRANCH=main

        # Security
        FORGEJO__security__INSTALL_LOCK=true
        FORGEJO__security__SECRET_KEY=$SECRET_KEY

        # Service
        FORGEJO__service__DISABLE_REGISTRATION=true
        FORGEJO__service__REQUIRE_SIGNIN_VIEW=true
        FORGEJO__service__DEFAULT_KEEP_EMAIL_PRIVATE=true

        # Session
        FORGEJO__session__PROVIDER=memory

        # Log
        FORGEJO__log__MODE=console
        FORGEJO__log__LEVEL=Info

        # Mailer
        FORGEJO__mailer__ENABLED=true
        FORGEJO__mailer__PROTOCOL=smtp+starttls
        FORGEJO__mailer__SMTP_ADDR=${smtpHost}
        FORGEJO__mailer__SMTP_PORT=${smtpPort}
        FORGEJO__mailer__USER=${smtpUser}
        FORGEJO__mailer__PASSWD=$SMTP_PASSWORD
        FORGEJO__mailer__FROM=Forgejo <forgejo@${emailDomain}>

        # Other
        FORGEJO__other__SHOW_FOOTER_VERSION=false
        EOF
        chmod 600 /var/lib/forgejo/forgejo.env
      '';

      # PostgreSQL database container
      virtualisation.oci-containers.containers.forgejo-db = {
        image = "postgres:16-alpine";
        autoStart = true;
        volumes = [
          "/srv/forgejo/db:/var/lib/postgresql/data"
        ];
        extraOptions = [
          "--network=forgejo-net"
          "--health-cmd=pg_isready -U forgejo"
          "--health-interval=10s"
          "--health-timeout=5s"
          "--health-retries=5"
        ];
        environmentFiles = ["/var/lib/forgejo/db.env"];
      };

      # Main Forgejo application
      virtualisation.oci-containers.containers.forgejo = {
        image = "codeberg.org/forgejo/forgejo:9";
        autoStart = true;
        dependsOn = ["forgejo-db"];
        volumes = [
          "/srv/forgejo/data:/data"
          "/srv/forgejo/git:/data/git"
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"
        ];
        ports = ["127.0.0.1:${toString port}:3000"];
        extraOptions = [
          "--network=forgejo-net"
          "--health-cmd=curl -sf http://localhost:3000/api/healthz || exit 1"
          "--health-interval=30s"
          "--health-timeout=10s"
          "--health-retries=5"
          "--health-start-period=60s"
        ];
        environmentFiles = ["/var/lib/forgejo/forgejo.env"];
        environment = {
          USER_UID = "1000";
          USER_GID = "1000";
        };
      };

      # Create admin user on first run
      systemd.services.forgejo-create-admin = {
        description = "Create Forgejo admin user";
        after = ["docker-forgejo.service"];
        requires = ["docker-forgejo.service"];
        wantedBy = ["multi-user.target"];
        path = with pkgs; [docker curl];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        script = ''
          set -euo pipefail

          ADMIN_PASSWORD=$(cat ${config.age.secrets.forgejo-admin-password.path})

          # Wait for Forgejo to be ready (403 is expected with REQUIRE_SIGNIN_VIEW)
          echo "Waiting for Forgejo to be ready..."
          for i in $(seq 1 30); do
            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:${toString port}/ || echo "000")
            if [ "$HTTP_CODE" != "000" ]; then
              echo "Forgejo is ready (HTTP $HTTP_CODE)"
              break
            fi
            if [ "$i" -eq 30 ]; then
              echo "Timeout waiting for Forgejo"
              exit 1
            fi
            sleep 2
          done

          # Check if admin user already exists
          if docker exec -u 1000 forgejo forgejo admin user list --admin 2>/dev/null | grep -q "${adminUsername}"; then
            echo "Admin user already exists, skipping creation"
            exit 0
          fi

          # Create admin user
          echo "Creating admin user..."
          docker exec -u 1000 forgejo forgejo admin user create \
            --admin \
            --username ${adminUsername} \
            --password "$ADMIN_PASSWORD" \
            --email "${myvars.userEmail}"

          echo "Admin user created successfully"
        '';
      };

      # GitHub sync service (runs hourly to mirror repos)
      systemd.services.forgejo-sync-github = {
        description = "Sync GitHub repositories to Forgejo";
        after = ["docker-forgejo.service"];
        requires = ["docker-forgejo.service"];
        path = with pkgs; [curl jq git docker];

        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };

        script = ''
          set -euo pipefail

          GITHUB_TOKEN=$(cat ${config.age.secrets.github-token.path})
          FORGEJO_ADMIN_PASSWORD=$(cat ${config.age.secrets.forgejo-admin-password.path})
          FORGEJO_URL="http://127.0.0.1:${toString port}"

          # Get list of GitHub repos for user ${adminUsername}
          REPOS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/user/repos?per_page=100&affiliation=owner" | \
            jq -r '.[] | "\(.name) \(.clone_url) \(.private)"')

          echo "Found GitHub repositories to mirror:"
          echo "$REPOS"

          # For each repo, create a mirror in Forgejo if it doesn't exist
          while read -r REPO_NAME REPO_URL REPO_PRIVATE; do
            [ -z "$REPO_NAME" ] && continue

            echo "Processing repository: $REPO_NAME"

            # Check if repo already exists in Forgejo
            STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
              -u "${adminUsername}:$FORGEJO_ADMIN_PASSWORD" \
              "$FORGEJO_URL/api/v1/repos/${adminUsername}/$REPO_NAME")

            if [ "$STATUS" -eq 404 ]; then
              echo "Creating mirror for $REPO_NAME..."

              # Create new repository mirror
              curl -s -X POST \
                -u "${adminUsername}:$FORGEJO_ADMIN_PASSWORD" \
                -H "Content-Type: application/json" \
                "$FORGEJO_URL/api/v1/repos/migrate" \
                -d "{
                  \"clone_addr\": \"$REPO_URL\",
                  \"repo_name\": \"$REPO_NAME\",
                  \"mirror\": true,
                  \"private\": $REPO_PRIVATE,
                  \"auth_token\": \"$GITHUB_TOKEN\"
                }" > /dev/null

              echo "Mirror created for $REPO_NAME"
            else
              echo "Repository $REPO_NAME already exists, syncing..."

              # Trigger sync for existing mirror
              curl -s -X POST \
                -u "${adminUsername}:$FORGEJO_ADMIN_PASSWORD" \
                "$FORGEJO_URL/api/v1/repos/${adminUsername}/$REPO_NAME/mirror-sync" > /dev/null

              echo "Sync triggered for $REPO_NAME"
            fi
          done <<< "$REPOS"

          echo "GitHub sync completed successfully"

          # Send success notification to ntfy (localhost, no auth needed)
          ${pkgs.curl}/bin/curl -H "Title: Forgejo GitHub Sync Success" \
            -H "Priority: default" \
            -H "Tags: forgejo,github" \
            -d "Successfully synced GitHub repositories to Forgejo" \
            http://127.0.0.1:${toString config.ports.ntfy}/alerts
        '';

        onFailure = ["forgejo-sync-failure.service"];
      };

      # Failure notification service for GitHub sync
      systemd.services.forgejo-sync-failure = {
        description = "Notify Forgejo GitHub sync failure";
        path = with pkgs; [curl];
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          curl -H "Title: Forgejo GitHub Sync Failed" \
            -H "Priority: urgent" \
            -H "Tags: forgejo,github,failure" \
            -d "Forgejo GitHub sync FAILED. Check journalctl for details." \
            http://127.0.0.1:${toString config.ports.ntfy}/alerts
        '';
      };

      # Timer to run GitHub sync hourly
      systemd.timers.forgejo-sync-github = {
        description = "Timer for Forgejo GitHub sync";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
          RandomizedDelaySec = "5m";
        };
      };
    }
    (mylib.dockerHelpers.mkDockerNetwork {
      inherit config;
      name = "forgejo";
      networkName = "forgejo-net";
    })
    (mylib.dockerHelpers.mkContainerNetworkDeps {
      name = "forgejo";
      containers = ["forgejo-db" "forgejo"];
    })
    {
      services.traefik.dynamicConfigOptions.http = mylib.traefikHelpers.mkTraefikRoute {
        name = "forgejo";
        inherit domain port;
      };
    }
    (mylib.dockerHelpers.mkDatabaseDumpService {
      inherit config pkgs;
      name = "forgejo";
      description = "Dump Forgejo PostgreSQL database";
      containerDeps = ["forgejo-db"];
      dumpCommand = ''
        DB_PASSWORD=$(cat ${config.age.secrets.forgejo-db-password.path})
        ${config.virtualisation.docker.package}/bin/docker exec forgejo-db \
          pg_dump -U forgejo -d forgejo > "$BACKUP_DIR/forgejo.sql.tmp"
        mv "$BACKUP_DIR/forgejo.sql.tmp" "$BACKUP_DIR/forgejo.sql"
      '';
    })
  ]
