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
      casks = ["nikitabobko/tap/aerospace"];
      taps = [
        "tw93/tap"
        "nikitabobko/tap"
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
    ];
    taps = [
      "homebrew/services"
      "nikitabobko/tap"
      "tw93/tap"
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
      "modrinth" # Minecraft Launcher
      "discord"
      "krita"
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
