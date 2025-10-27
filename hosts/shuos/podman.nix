{
  pkgs,
  myvars,
  ...
}: {
  virtualisation = {
    oci-containers.backend = "podman";

    podman = {
      enable = true;
      dockerCompat = true; # Create docker alias for podman
      dockerSocket.enable = true; # Enable docker socket compatibility
      defaultNetwork.settings.dns_enabled = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };
  };

  users.users."${myvars.username}".extraGroups = ["podman"];

  environment.systemPackages = with pkgs; [
    podman-compose # Docker-compose for podman
    podman-tui # Terminal UI for podman
  ];
}
