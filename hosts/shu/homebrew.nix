{...}: {
  homebrew = {
    # Disabled for fast deployments, enable when needed (updates and un/installations)
    enable = false;
    brews = [
      "posting"
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
      "google-drive" # Google Drive Sync
      "proton-drive" # Proton Drive Sync

      "notion"
      "notion-mail"
      "notion-calendar"

      # "proton-vpn" Unavailable in the current region

      # Rarely used
      "discord"
      "obsidian" # Markdown note taking app
      "hiddenbar" # Hide menu bar items

      # Temporary / Testing
      "zed"
      "spacedrive" # Virtual Distributed File System
      "lm-studio" # Model runner
      "claude" # Claude Desktop App for MCP
      "chatgpt" # ChatGPT Desktop App
      "wezterm" # Terminal emulator
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
