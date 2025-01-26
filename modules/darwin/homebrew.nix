{...}: {
  homebrew = {
    # Disabled for fast deployments, enable when needed (updates and un/installations)
    enable = false;
    brews = [
      "azure-cli"
    ];
    taps = [
      "homebrew/services"
    ];
    casks = [
      "arc"
      "bitwarden"
      "discord"
      "hiddenbar"
      "intellij-idea-ce"
      "docker"
      "blackhole-16ch"
      "whatsapp"
      "oversight"
      "notion"
      "notion-calendar"
      "figma"
      "raycast"
      "monitorcontrol"
      "burp-suite"
      "wezterm"
      "postman"
      "middleclick"
      "google-drive"
      "MonitorControl"
      "obsidian"
      "google-cloud-sdk"
      "balenaetcher"
      "cloudflare-warp"
      "lens"
      "burp-suite"
      "pgadmin4"
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
