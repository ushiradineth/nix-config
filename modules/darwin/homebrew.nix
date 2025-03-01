{...}: {
  homebrew = {
    # Disabled for fast deployments, enable when needed (updates and un/installations)
    enable = true;
    brews = [
      "posting"
    ];
    taps = [
      "homebrew/services"
    ];
    casks = [
      "arc"
      "bitwarden"
      "discord"
      "hiddenbar" # hide menu bar items
      "intellij-idea-ce" # java ide
      "docker"
      "whatsapp"
      "oversight" # notify when camera is on
      "notion"
      "notion-calendar"
      "figma"
      "raycast"
      "monitorcontrol" # brightness control for external monitors
      "wezterm"
      "middleclick" # middleclick or three finger click control
      "google-drive"
      "obsidian"
      "balenaetcher"
      "cloudflare-warp"
      "burp-suite"
      "microsoft-azure-storage-explorer"
    ];
    masApps = {
      "Horo" = 1437226581;
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
