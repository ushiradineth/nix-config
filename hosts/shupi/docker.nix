{pkgs, ...}: {
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  users.users.shu.extraGroups = ["docker"];
}
