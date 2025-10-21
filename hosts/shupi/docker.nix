{myvars, ...}: {
  virtualisation = {
    oci-containers.backend = "docker";

    docker = {
      enable = true;
      enableOnBoot = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };
  };

  users.users."${myvars.username}".extraGroups = ["docker"];
}
