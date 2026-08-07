{
  lib,
  myvars,
  pkgs,
  ...
}: {
  services.openssh =
    {enable = true;}
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
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
