{
  lib,
  myvars,
  ...
}: {
  networking.firewall.enable = lib.mkDefault false;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    openFirewall = true;
  };

  # Add terminfo database of all known terminals to the system profile.
  # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/config/terminfo.nix
  environment.enableAllTerminfo = true;
}
