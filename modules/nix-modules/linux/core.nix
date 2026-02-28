{lib, ...}: {
  nixpkgs.config.allowUnfree = true;

  nix.enable = true;

  # Scheduled weekly garbage collection
  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 7d";
  };

  nix.settings.auto-optimise-store = false;

  nix.channel.enable = false;

  # For running dynamically linked binaries
  programs.nix-ld.enable = true;

  system.stateVersion = "25.11";
}
