{lib, ...}: {
  nix.enable = true;

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

  nix.settings.auto-optimise-store = false;

  nix.channel.enable = false;
}
