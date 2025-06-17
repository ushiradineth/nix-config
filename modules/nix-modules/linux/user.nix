{
  pkgs,
  myvars,
  config,
  ...
}: {
  users.groups."${myvars.username}" = {};

  # Enable zsh for initial login
  programs.zsh.enable = true;

  users.users."${myvars.username}" = {
    description = myvars.userFullname;
    initialHashedPassword = myvars.initialHashedPassword;
    home = "/home/${myvars.username}";
    group = "${myvars.username}";
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [
      "users"
      "networkmanager"
      "wheel"
      "input"
    ];
  };

  users.users.root = {
    initialHashedPassword = config.users.users."${myvars.username}".initialHashedPassword;
  };
}
