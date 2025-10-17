{
  myvars,
  mysecrets,
  ...
}: {
  age.identityPaths = [
    "/Users/${myvars.username}/.ssh/shu"
  ];

  age.secrets = {
    asd = {
      file = "${mysecrets}/asd.age";
      path = "/Users/shu/Code/asd";
    };

    # # Uncomment when ready to use
    # tailscale-authkey = {
    #   file = mylib.relativeToRoot "secrets/shupi/tailscale-authkey.age";
    # };
    #
    # traefik-cf-api-key = {
    #   file = mylib.relativeToRoot "secrets/shupi/traefik-cf-api-key.age";
    # };
    #
    # cloudflare-tunnel = {
    #   file = mylib.relativeToRoot "secrets/shupi/cloudflare-tunnel.age";
    # };
    #
    # opencloud-admin-password = {
    #   file = mylib.relativeToRoot "secrets/shupi/opencloud-admin-password.age";
    # };
  };
}
