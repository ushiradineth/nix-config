{self, ...}: {
  # Add ability to used TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;

  system = {
    stateVersion = 5;
    configurationRevision = self.rev or self.dirtyRev or null;

    defaults = {
      menuExtraClock.Show24Hour = true;

      dock = {
        autohide = true;
        autohide-delay = 0.01;
        autohide-time-modifier = 0.01;
        show-recents = false;
        magnification = false;
        orientation = "right";
        mru-spaces = false;
        expose-group-apps = true;
        persistent-apps = [
          "/Applications/Zen.app"
          "/Applications/Ghostty.app"
          "/Applications/Notion.app"
          "/Applications/Notion Calendar.app"
        ];
        tilesize = 32;
      };

      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        CreateDesktop = false;
        FXDefaultSearchScope = "SCcf";
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "clmv";
        _FXShowPosixPathInTitle = true; # Show full path in finder title
        QuitMenuItem = true;
        ShowPathbar = true;
        ShowStatusBar = true;
      };

      trackpad = {
        ActuationStrength = 0;
        Clicking = true;
        TrackpadRightClick = true;
      };

      loginwindow = {
        GuestEnabled = false; # Disable guest user
        SHOWFULLNAME = true; # Show full name in login window
      };

      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
        AppleKeyboardUIMode = 3; # Mode 3 enables full keyboard control.
        ApplePressAndHoldEnabled = true; # Enable press and hold
        AppleICUForce24HourTime = true; # Show 24 hour clock
        AppleShowAllExtensions = true; # Show all extensions in finder
        AppleShowAllFiles = true; # Show all files in finder

        # If you press and hold certain keyboard keys when in a text area, the key’s character begins to repeat.
        # This is very useful for vim users, they use `hjkl` to move cursor.
        # sets how long it takes before it starts repeating.
        InitialKeyRepeat = 15;
        KeyRepeat = 3;

        "com.apple.swipescrolldirection" = true; # Enable natural scrolling
        "com.apple.sound.beep.feedback" = 0; # Disable beep sound when pressing volume up/down key
        "com.apple.mouse.tapBehavior" = 1; # Enable tap to click

        NSAutomaticCapitalizationEnabled = false; # Disable auto capitalization
        NSAutomaticDashSubstitutionEnabled = false; # Disable auto dash substitution
        NSAutomaticPeriodSubstitutionEnabled = false; # Disable auto period substitution
        NSAutomaticQuoteSubstitutionEnabled = false; # Disable auto quote substitution
        NSAutomaticSpellingCorrectionEnabled = false; # Disable auto spelling correction
        NSNavPanelExpandedStateForSaveMode = true; # Expand save panel by default
        NSNavPanelExpandedStateForSaveMode2 = true;
      };

      ".GlobalPreferences" = {
        "com.apple.mouse.scaling" = -1.0; # Disable mouse scaling / acceleration
      };

      CustomUserPreferences = {
        ".GlobalPreferences" = {
          # automatically switch to a new space when switching to the application
          AppleSpacesSwitchOnActivate = true;
        };
        NSGlobalDomain = {
          # Add a context menu item for showing the Web Inspector in web views
          WebKitDeveloperExtras = true;
        };
        "com.apple.finder" = {
          ShowExternalHardDrivesOnDesktop = true;
          ShowHardDrivesOnDesktop = true;
          ShowMountedServersOnDesktop = true;
          ShowRemovableMediaOnDesktop = true;
          _FXSortFoldersFirst = true;
          FXDefaultSearchScope = "SCcf";
        };
        "com.apple.desktopservices" = {
          # Avoid creating .DS_Store files on network or USB volumes
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
        "com.apple.spaces" = {
          "spans-displays" = false;
        };
        "com.apple.WindowManager" = {
          EnableStandardClickToShowDesktop = 0; # Click wallpaper to reveal desktop
          StandardHideDesktopIcons = 0; # Show items on desktop
          HideDesktop = 0; # Do not hide items on desktop & stage manager
          StageManagerHideWidgets = 0;
          StandardHideWidgets = 0;
        };
        "com.apple.screensaver" = {
          # Require password immediately after sleep or screen saver begins
          askForPassword = 1;
          askForPasswordDelay = 0;
        };
        "com.apple.screencapture" = {
          location = "~/Desktop";
          type = "png";
        };
        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false;
        };
        # Prevent Photos from opening automatically when devices are plugged in
        "com.apple.ImageCapture".disableHotPlug = true;
      };
    };
  };
}
