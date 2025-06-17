{myvars, ...}: {
  services.openssh = {
    enable = true;
  };

  users.users.${myvars.username}.openssh.authorizedKeys.keys = myvars.authorizedKeys;
}
