{
  config,
  mylib,
  myvars,
  hostname,
  mysecrets,
  ...
}: let
  port = config.ports.backrest;
  hetznerUser = config.environment.variables.HETZNER_USER;
  hetznerHost = config.environment.variables.HETZNER_HOST;
  repoBase = "sftp://${hetznerUser}@${hetznerHost}:23/backups/shupi";
in {
  age.secrets.restic-password = {
    file = "${mysecrets}/${hostname}/restic-password.age";
    mode = "0400";
  };

  system.activationScripts.backrest-setup = ''
        mkdir -p /srv/backrest/{data,config,cache,tmp,ssh}

        # Create SSH known_hosts with Hetzner's host key
        cat > /srv/backrest/ssh/known_hosts << 'EOF'
    [${hetznerHost}]:23 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw==
    EOF
        chmod 644 /srv/backrest/ssh/known_hosts

        # Copy the SSH private key for Hetzner Storage Box
        cp /home/shu/.ssh/hetzner /srv/backrest/ssh/id_rsa
        chmod 600 /srv/backrest/ssh/id_rsa

        RESTIC_PASSWORD=$(cat ${config.age.secrets.restic-password.path} | tr -d '[:space:]')

        # Only generate initial config.json if it doesn't exist
        # This preserves user settings (auth, instance, etc.) between deployments
        if [ ! -f /srv/backrest/config/config.json ]; then
          # Generate initial config.json with all four existing repositories
          # SSH key authentication is configured automatically using /home/shu/.ssh/hetzner
          cat > /srv/backrest/config/config.json << EOF
    {
      "modno": 3,
      "version": 4,
      "instance": "shupi",
      "repos": [
        {
          "id": "app-data",
          "uri": "${repoBase}/app-data",
          "guid": "413bd03f0db35553a16793b5a1bb902477c07e126fc3e421a9da4f5c78750a39",
          "password": "$RESTIC_PASSWORD"
        },
        {
          "id": "config",
          "uri": "${repoBase}/config",
          "guid": "24468c485be8a7b4703059738a213be0c37b0f1b746b2b3526ddd34bb368e2f4",
          "password": "$RESTIC_PASSWORD"
        },
        {
          "id": "critical-data",
          "uri": "${repoBase}/critical-data",
          "guid": "1f5915a4a334bc9ea94093fbf8741d9b8dc677403f859a29db0c80486a32943e",
          "password": "$RESTIC_PASSWORD"
        },
        {
          "id": "db-dumps",
          "uri": "${repoBase}/db-dumps",
          "guid": "1b0feae9a9b9ea9cd974936591be4a4cdff3378ea18325a17b37e74f9ee25d27",
          "password": "$RESTIC_PASSWORD"
        }
      ],
      "auth": {
        "users": [
          {
            "name": "ushiradineth",
            "passwordBcrypt": "JDJhJDEwJE5IUy5hQlBKMkxwWnF5L1JUVnFDOU9lMnVNL0FDMlB5ZkFQY0l3RVUuWHhmOE1McDE1VTJ5"
          }
        ]
      },
      "sync": {
        "identity": {
          "keyId": "ecdsa.ZYDFtvIJMO5eLzbcbeuCfBqGnx7o_GMVwv4ofCr4P4o"
        }
      }
    }
    EOF
          chmod 600 /srv/backrest/config/config.json
        fi
  '';

  virtualisation.oci-containers.containers.backrest = {
    image = "garethgeorge/backrest:v1.11.2";
    autoStart = true;
    volumes = [
      "/srv/backrest/data:/data"
      "/srv/backrest/config:/config"
      "/srv/backrest/cache:/cache"
      "/srv/backrest/tmp:/tmp"
      "/srv/backrest/ssh/known_hosts:/root/.ssh/known_hosts:ro"
      "/srv/backrest/ssh/id_rsa:/root/.ssh/id_rsa:ro"
    ];
    environment = {
      BACKREST_DATA = "/data";
      BACKREST_CONFIG = "/config/config.json";
      XDG_CACHE_HOME = "/cache";
      TMPDIR = "/tmp";
      TZ = myvars.timezone;
    };
    ports = ["127.0.0.1:${toString port}:9898"];
    extraOptions = [
      "--health-cmd=wget -qO- http://localhost:9898/ || exit 1"
      "--health-interval=30s"
      "--health-timeout=10s"
      "--health-retries=5"
      "--health-start-period=30s"
    ];
  };

  services.traefik.dynamicConfigOptions.http = mylib.traefikHelpers.mkTraefikRoute {
    name = "backrest";
    domain = config.environment.variables.BACKREST_DOMAIN;
    inherit port;
  };
}
