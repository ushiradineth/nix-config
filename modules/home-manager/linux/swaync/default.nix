{lib, ...}: let
  catppuccin = builtins.readFile ./catppuccin-frappe.css;
in {
  services.swaync = {
    enable = true;
    style = lib.concatStringsSep "\n" [
      catppuccin
      ''
        /* Transparent blur theme overrides */
        .control-center {
          background: rgba(48, 52, 70, 0.5);
          border-radius: 12px;
          border: 1px solid rgba(255, 255, 255, 0.05);
          box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
        }

        .floating-notifications.background .notification-row .notification-background {
          background: rgba(48, 52, 70, 0.5);
          border-radius: 12px;
          border: 1px solid rgba(255, 255, 255, 0.05);
          box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
        }

        .control-center .notification-row .notification-background {
          background: rgba(255, 255, 255, 0.05);
          border-radius: 8px;
          box-shadow: none;
        }

        .control-center .widget-title button,
        .control-center .notification-row .notification-background .notification > *:last-child > * .notification-action {
          background: rgba(255, 255, 255, 0.05);
          box-shadow: none;
          border: 1px solid rgba(255, 255, 255, 0.1);
        }

        .control-center .widget-title button:hover,
        .control-center .notification-row .notification-background .notification > *:last-child > * .notification-action:hover {
          background: rgba(255, 255, 255, 0.1);
        }

        .widget-dnd > switch,
        .control-center-dnd {
          background: rgba(255, 255, 255, 0.05);
          border: 1px solid rgba(255, 255, 255, 0.1);
        }

        .widget-dnd > switch slider,
        .control-center-dnd slider {
          background: rgba(255, 255, 255, 0.3);
        }
      ''
    ];
  };
}
