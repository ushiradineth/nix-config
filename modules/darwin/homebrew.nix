{...}: {
  homebrew = {
    # Disabled for fast deployments, enable when needed (updates and un/installations)
    enable = true;
    brews = [
      "posting"
    ];
    taps = [
      "homebrew/services"
      "nikitabobko/tap"
    ];
    casks = [
      "arc"
      "aerospace" # Tiling window manager
      "bitwarden"
      "discord"
      "hiddenbar" # Hide menu bar items
      "whatsapp"
      "oversight" # Notify when camera is on
      "notion"
      "notion-mail"
      "notion-calendar"
      "figma"
      "raycast"
      "monitorcontrol" # Brightness control for external monitors
      "wezterm"
      "middleclick" # Middle click or three finger click control
      "google-drive"
      "obsidian"
      "balenaetcher"
      "cloudflare-warp"
      "burp-suite"
      "shottr" # Screenshot tool
      "orbstack"
      "lm-studio" # Model runner
      "claude" # Claude Desktop App for MCP
      "chatgpt" # ChatGPT Desktop App
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
