{myvars, ...}: {
  # Define a user account. Don't forget to set a password with ‘passwd’.
  system.primaryUser = myvars.username;
  users.users."${myvars.username}" = {
    home = "/Users/${myvars.username}";
  };
}
