{
  pkgs,
  myvars,
  ...
}: {
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = myvars.username;
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
      };
    };
  };
}
