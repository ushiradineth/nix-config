{myvars, ...}: {
  environment.variables = {
    ACME_EMAIL = myvars.userEmail;
    EMAIL_DOMAIN = "shupi.ushira.com";

    # Exposed through Tailscale tailnet
    UPTIMEKUMA_DOMAIN = "up.shupi.ushira.com";
    ACTUALBUDGET_DOMAIN = "ab.shupi.ushira.com";
    PORTAINER_DOMAIN = "pt.shupi.ushira.com";
    ADGUARD_DOMAIN = "ad.shupi.ushira.com";
    TRAEFIK_DOMAIN = "tr.shupi.ushira.com";
    VICTORIAMETRICS_DOMAIN = "vm.shupi.ushira.com";
    VICTORIALOGS_DOMAIN = "vl.shupi.ushira.com";
    HOMEPAGE_DOMAIN = "home.shupi.ushira.com";
    IMMICH_DOMAIN = "im.shupi.ushira.com";
    SEAFILE_DOMAIN = "sf.shupi.ushira.com";
    COUCHDB_DOMAIN = "couchdb.shupi.ushira.com";

    # Exposed through Cloudflared
    UMAMI_DOMAIN = "umami.ushira.com";
    WAKAPI_DOMAIN = "wakapi.ushira.com";
    INFISICAL_DOMAIN = "infisical.ushira.com";
  };
}
