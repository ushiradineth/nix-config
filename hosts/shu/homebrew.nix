{...}: {
  homebrew = {
    # Disabled for fast deployments, enable when needed (updates and un/installations)
    enable = false;
    brews = [
      "posting"
      "codex"
    ];
    taps = [
      "homebrew/services"
      "nikitabobko/tap"
    ];
    casks = [
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
      "cloudflare-warp" # Cloudflare WARP / Zero Trust VPN
      "burp-suite" # Web testing tool
      "ghostty" # Terminal emulator
      "orbstack" # Drop in replacement for Docker Desktop
      "whatsapp"
      "opencloud" # OpenCloud Sync
      "google-drive"
      "modrinth" # Minecraft Launcher
      "hiddenbar" # Hide menu bar items
      "discord"
      "krita"
      "wacom-tablet"
      "medibangpaintpro"
      "notion"
      "notion-calendar"
      "tailscale-app"
      "protonvpn"
      "visual-studio-code" # For Dev Containers
      "claude-code"
      "conductor" # Claude Code Parallelisation
      "drawpen" # For presentations (sketching on the screen)
      "utm" # Virtual Machines
      "affinity" # Photo editing
      "obsidian"
      "seafile-client"
    ];
    masApps = {
      "Davinci Resolve" = 571213070;
    };
    onActivation = {
      autoUpdate = true; # Fetch the newest stable branch of Homebrew's git repo
      upgrade = true; # Upgrade outdated casks, formulae, and App Store apps
      # 'zap': uninstalls all formulae(and related files) not listed in the generated Brewfile
      cleanup = "zap";
    };
  };
}
