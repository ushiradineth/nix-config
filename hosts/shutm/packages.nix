{
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = lib.mkForce (with pkgs; [
    spice-vdagent
    glxinfo
  ]);
}
