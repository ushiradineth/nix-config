{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    extraConfig.pipewire = {
      "10-clock-rate" = {
        "context.properties" = {
          "default.clock.allowed-rates" = [44100 48000 96000];
        };
      };
    };
    wireplumber = {
      enable = true;
      extraConfig = {
        "10-hdmi-audio" = {
          "monitor.alsa.rules" = [
            {
              matches = [{"device.name" = "alsa_card.pci-0000_06_00.1";}];
              actions = {
                update-props = {
                  "api.acp.auto-profile" = true;
                  "device.profile" = "hdmi-stereo";
                  "audio.format" = "S32LE";
                  "audio.rate" = 48000;
                };
              };
            }
          ];
        };
      };
    };
  };
}
