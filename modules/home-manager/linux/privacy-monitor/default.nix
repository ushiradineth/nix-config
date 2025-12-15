{
  pkgs,
  lib,
  ...
}: let
  privacyMonitor = pkgs.writeShellScriptBin "privacy-monitor" ''
    #!/usr/bin/env bash

    STATE_DIR="$XDG_RUNTIME_DIR/privacy-monitor"
    mkdir -p "$STATE_DIR"

    MIC_STATE_FILE="$STATE_DIR/mic_state"
    CAM_STATE_FILE="$STATE_DIR/cam_state"
    SCREEN_STATE_FILE="$STATE_DIR/screen_state"

    check_mic() {
      # Check for active audio capture streams via PipeWire
      # Look for input streams with [active] in the Audio section
      if ${pkgs.wireplumber}/bin/wpctl status 2>/dev/null | ${pkgs.gawk}/bin/awk '/^Audio/,/^Video/' | ${pkgs.gawk}/bin/awk '/Streams:/,/^$/' | grep -E 'input.*\[active\]' | grep -qv '^$'; then
        echo "active"
      else
        echo "inactive"
      fi
    }

    check_camera() {
      # Check for active camera streams via PipeWire (V4L2 devices only, not screen capture)
      # Look for video streams that are NOT from xdg-desktop-portal (screen sharing)
      if ${pkgs.wireplumber}/bin/wpctl status 2>/dev/null | ${pkgs.gawk}/bin/awk '/^Video/,/^Settings/' | ${pkgs.gawk}/bin/awk '/Streams:/,/^$/' | grep -E '\[active\]' | grep -qvE 'portal'; then
        echo "active"
      else
        echo "inactive"
      fi
    }

    check_screen() {
      # Check for active screen sharing via xdg-desktop-portal
      if ${pkgs.wireplumber}/bin/wpctl status 2>/dev/null | ${pkgs.gawk}/bin/awk '/^Video/,/^Settings/' | ${pkgs.gawk}/bin/awk '/Streams:/,/^$/' | grep -E '\[active\]' | grep -qE 'portal'; then
        echo "active"
      else
        echo "inactive"
      fi
    }

    notify_change() {
      local device="$1"
      local state="$2"
      local icon=""
      local message=""

      if [ "$device" = "mic" ]; then
        if [ "$state" = "active" ]; then
          icon="microphone-sensitivity-high-symbolic"
          message="Microphone is now active"
        else
          icon="microphone-sensitivity-muted-symbolic"
          message="Microphone is no longer active"
        fi
      elif [ "$device" = "camera" ]; then
        if [ "$state" = "active" ]; then
          icon="camera-web-symbolic"
          message="Camera is now active"
        else
          icon="camera-disabled-symbolic"
          message="Camera is no longer active"
        fi
      elif [ "$device" = "screen" ]; then
        if [ "$state" = "active" ]; then
          icon="video-display-symbolic"
          message="Screen sharing is now active"
        else
          icon="video-display-symbolic"
          message="Screen sharing has ended"
        fi
      fi

      ${pkgs.libnotify}/bin/notify-send "Privacy Alert" "$message" -i "$icon" -u normal
    }

    waybar_output() {
      local device="$1"
      local state=""
      local text=""
      local tooltip=""
      local class=""

      if [ "$device" = "mic" ]; then
        state=$(check_mic)
        if [ "$state" = "active" ]; then
          text=$(printf '\uf130')
          tooltip="Microphone is active"
          class="active"
        else
          text=""
          tooltip="Microphone is inactive"
          class="inactive"
        fi
      elif [ "$device" = "camera" ]; then
        state=$(check_camera)
        if [ "$state" = "active" ]; then
          text=$(printf '\uf03d')
          tooltip="Camera is active"
          class="active"
        else
          text=""
          tooltip="Camera is inactive"
          class="inactive"
        fi
      elif [ "$device" = "screen" ]; then
        state=$(check_screen)
        if [ "$state" = "active" ]; then
          text=$(printf '\uf108')
          tooltip="Screen sharing is active"
          class="active"
        else
          text=""
          tooltip="Screen sharing is inactive"
          class="inactive"
        fi
      fi

      echo "{\"text\": \"$text\", \"tooltip\": \"$tooltip\", \"class\": \"$class\"}"
    }

    daemon_mode() {
      # Initialize state files
      echo "inactive" > "$MIC_STATE_FILE"
      echo "inactive" > "$CAM_STATE_FILE"

      while true; do
        # Check microphone
        current_mic=$(check_mic)
        previous_mic=$(cat "$MIC_STATE_FILE" 2>/dev/null || echo "inactive")
        if [ "$current_mic" != "$previous_mic" ]; then
          echo "$current_mic" > "$MIC_STATE_FILE"
          notify_change "mic" "$current_mic"
        fi

        # Check camera
        current_cam=$(check_camera)
        previous_cam=$(cat "$CAM_STATE_FILE" 2>/dev/null || echo "inactive")
        if [ "$current_cam" != "$previous_cam" ]; then
          echo "$current_cam" > "$CAM_STATE_FILE"
          notify_change "camera" "$current_cam"
        fi

        # Check screen sharing
        current_screen=$(check_screen)
        previous_screen=$(cat "$SCREEN_STATE_FILE" 2>/dev/null || echo "inactive")
        if [ "$current_screen" != "$previous_screen" ]; then
          echo "$current_screen" > "$SCREEN_STATE_FILE"
          notify_change "screen" "$current_screen"
        fi

        sleep 2
      done
    }

    case "$1" in
      "mic-status")
        waybar_output "mic"
        ;;
      "camera-status")
        waybar_output "camera"
        ;;
      "screen-status")
        waybar_output "screen"
        ;;
      "daemon")
        daemon_mode
        ;;
      *)
        echo "Usage: privacy-monitor {mic-status|camera-status|screen-status|daemon}"
        echo "  mic-status    - Output mic status JSON for waybar"
        echo "  camera-status - Output camera status JSON for waybar"
        echo "  screen-status - Output screen sharing status JSON for waybar"
        echo "  daemon        - Run as daemon to send notifications on state change"
        exit 1
        ;;
    esac
  '';
in {
  home.packages = [privacyMonitor];

  systemd.user.services.privacy-monitor = {
    Unit = {
      Description = "Privacy monitor daemon for mic/camera access notifications";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${privacyMonitor}/bin/privacy-monitor daemon";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };
}
