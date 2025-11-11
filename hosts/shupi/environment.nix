{myvars, ...}: {
  environment.variables = {
    ACME_EMAIL = myvars.userEmail;
    UPTIMEKUMA_DOMAIN = "up.shupi.ushira.com";
    ACTUALBUDGET_DOMAIN = "ab.shupi.ushira.com";
    PORTAINER_DOMAIN = "pt.shupi.ushira.com";
    ADGUARD_DOMAIN = "ad.shupi.ushira.com";
    TRAEFIK_DOMAIN = "tr.shupi.ushira.com";
    GRAFANA_DOMAIN = "gr.shupi.ushira.com";
    HOMEPAGE_DOMAIN = "home.shupi.ushira.com";
    IMMICH_DOMAIN = "im.shupi.ushira.com";
    SEAFILE_DOMAIN = "sf.shupi.ushira.com";
    UMAMI_DOMAIN = "umami.ushira.com"; # Exposed through Cloudflared
  };
}
