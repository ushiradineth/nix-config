{
  pkgs,
  myvars,
  ...
}: {
  # Define a user account. Don't forget to set a password with ‘passwd’.
  system.primaryUser = myvars.username;

  users.users."${myvars.username}" = {
    description = myvars.userFullname;
    initialHashedPassword = myvars.initialHashedPassword;
    home = "/Users/${myvars.username}";
    shell = pkgs.zsh;
  };
}
