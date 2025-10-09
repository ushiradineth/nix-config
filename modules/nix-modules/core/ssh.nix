{
  lib,
  myvars,
  ...
}: {
  services.openssh = {
    enable = true;
  };

  users.users.${myvars.username}.openssh.authorizedKeys.keys = myvars.authorizedKeys;
  users.users.root.openssh.authorizedKeys.keys = myvars.authorizedKeys;

  programs.ssh.extraConfig =
    lib.attrsets.foldlAttrs
    (acc: host: ip:
      acc
      + ''
        Host ${host}
          HostName ${ip}
          Port 22
      '')
    ""
    (myvars.hostAddresses or {});
}
