{
  myvars,
  config,
  ...
}: {
  # Don't allow mutation of users outside the config.
  users.mutableUsers = false;

  users.users."${myvars.username}" = {
    inherit (myvars) initialHashedPassword;
    home = "/home/${myvars.username}";
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
