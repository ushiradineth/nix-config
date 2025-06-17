{
  pkgs,
  myvars,
  ...
}: {
  # Define a user account. Don't forget to set a password with ‘passwd’.
  system.primaryUser = myvars.username;

  # Enable zsh for initial login
  programs.zsh.enable = true;

  users.users."${myvars.username}" = {
    description = myvars.userFullname;
    home = "/Users/${myvars.username}";
    shell = pkgs.zsh;
  };
}
