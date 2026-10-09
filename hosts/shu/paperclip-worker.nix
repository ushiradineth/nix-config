{
  lib,
  myvars,
  pkgs,
  ...
}: let
  paperclipRoot = "/Users/${myvars.username}/.paperclip";
in {
  users.users.${myvars.username}.openssh.authorizedKeys.keys = [
    ''from="100.74.32.50",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFk1LV9zkEobez4+2FSML3FMeknRGjVwMwUNDRVCudys paperclip@shupi''
  ];

  system.activationScripts.postActivation.text = lib.mkAfter ''
    ${pkgs.coreutils}/bin/install -d -m 0700 -o ${myvars.username} -g staff ${paperclipRoot}
    ${pkgs.coreutils}/bin/install -d -m 0700 -o ${myvars.username} -g staff ${paperclipRoot}/workspaces
  '';
}
