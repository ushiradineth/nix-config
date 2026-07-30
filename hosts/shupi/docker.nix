{myvars, ...}: {
  virtualisation = {
    oci-containers.backend = "docker";

    docker = {
      enable = true;
      enableOnBoot = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = ["--all"];
      };
    };
  };

  users.users."${myvars.username}".extraGroups = ["docker"];
}
