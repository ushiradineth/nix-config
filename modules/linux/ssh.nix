{myvars, ...}: {
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  users.users.${myvars.username}.openssh.authorizedKeys.keys = myvars.authorizedKeys;
}
