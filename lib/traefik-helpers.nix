_: {
  mkTraefikRoute = {
    name,
    domain,
    port,
    scheme ? "http",
    host ? "localhost",
    certResolver ? "letsencrypt",
    entrypoints ? "websecure",
  }: {
    services."${name}".loadBalancer.servers = [
      {url = "${scheme}://${host}:${toString port}";}
    ];

    routers."${name}" = {
      rule = "Host(`${domain}`)";
      tls.certResolver = certResolver;
      service = name;
      inherit entrypoints;
    };
  };
}
