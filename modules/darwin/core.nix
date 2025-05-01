{lib, ...}: {
  # Scheduled weekly garbage collection
  nix.gc = {
    automatic = lib.mkDefault true;
    interval = lib.mkDefault {
      Weekday = 0;
      Hour = 0;
      Minute = 0;
    };
    options = lib.mkDefault "--delete-older-than 7d";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  nix.settings.auto-optimise-store = false;

  nix.channel.enable = false;

  system.stateVersion = 5;
}
