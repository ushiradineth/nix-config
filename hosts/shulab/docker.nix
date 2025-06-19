{myvars, ...}: {
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  users.groups.docker = {};
  users.users."${myvars.username}".extraGroups = ["docker"];
}
