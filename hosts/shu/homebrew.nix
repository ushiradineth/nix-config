{
  managedInstallsEnabled ? false,
  myvars,
  ...
}: {
  nix-homebrew = {
    enable = managedInstallsEnabled;
    user = myvars.username;
    enableRosetta = true;

    # Automatically migrate existing Homebrew installations
    autoMigrate = true;

    trust = {
      casks = [
        "nikitabobko/tap/aerospace"
        "kamillobinski/thock/thock"
      ];
      taps = [
        "tw93/tap"
        "nikitabobko/tap"
        "HaseebKhalid1507/tap"
        "kamillobinski/thock"
      ];
      # commands = ["user/repo/command"];
      # formulae = ["user/repo/formula"];
    };
  };

  homebrew = {
    # Keep disabled by default for faster rebuilds. Enable with --with-installs.
    enable = managedInstallsEnabled;
    brews = [
      "posting"
      "defaultbrowser"
      "agent-browser"
      "mole" # MacOS clean up utility
      "handbrake"
      "nvm"
      "czkawka"
      "myx"
    ];
    # Bundle cleanup replaces the trust store with the Brewfile's trusted entries.
    taps =
      ["homebrew/services"]
      ++ map (name: {
        inherit name;
        trusted = true;
      }) [
        "nikitabobko/tap"
        "tw93/tap"
        "HaseebKhalid1507/tap"
        "kamillobinski/thock"
      ];
    casks = [
      "obs"
      "vlc"
      "arc" # Arc - for work
      "zen" # Zen Browser
      "figma"
      "shottr" # Screenshot tool
      "raycast" # Enhanced Spotlight
      "aerospace" # Tiling window manager
      "oversight" # Notify when camera or microphone gets active
      "middleclick" # Middle click or three finger click control
      "monitorcontrol" # Brightness control for external monitors
      "bitwarden"
      "balenaetcher" # Burn OS images to USBs
      "burp-suite" # Web testing tool
      "ghostty" # Terminal emulator
      "orbstack" # Drop in replacement for Docker Desktop
      "whatsapp"
      "google-drive"
      "discord"
      "medibangpaintpro"
      "notion-calendar"
      "tailscale-app"
      "visual-studio-code" # For Dev Containers
      "drawpen" # For presentations (sketching on the screen)
      "utm" # Virtual Machines
      "affinity" # Photo editing
      "obsidian"
      "seafile-client"
      "insomnia"
      "helium-browser"
      "cloudflare-warp"
      "yubico-authenticator"
      "codex-app"
      "spotify"
      "modrinth" # Minecraft Launcher
      "osu"
      "handy" # Speech to text application
      "blankie" # Background noise
      "affine" # Note editor and whiteboard
      "dbx" # DB client
      "thock" # Keyboard sounds
      "atoll" # Dynamic Island
      "thaw" # Menu bar manager
    ];
    masApps = {
      "Xcode" = 497799835;
    };

    onActivation = {
      autoUpdate = false; # Fetch the newest stable branch of Homebrew's git repo
      upgrade = true; # Upgrade outdated casks, formulae, and App Store apps
      # 'zap': uninstalls all formulae(and related files) not listed in the generated Brewfile
      cleanup = "zap";
    };
  };
}
