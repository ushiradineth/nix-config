{myvars, ...}: {
  environment.variables = {
    ACME_EMAIL = myvars.userEmail;
    OC_DOMAIN = "oc.shupi.ushira.com";
    UPTIMEKUMA_DOMAIN = "up.shupi.ushira.com";
    ACTUALBUDGET_DOMAIN = "ab.shupi.ushira.com";
    PORTAINER_DOMAIN = "pt.shupi.ushira.com";
    ADGUARD_DOMAIN = "ad.shupi.ushira.com";
    TRAEFIK_DOMAIN = "tr.shupi.ushira.com";
    GRAFANA_DOMAIN = "gr.shupi.ushira.com";
  };
}
