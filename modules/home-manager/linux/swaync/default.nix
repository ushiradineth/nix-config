{...}: {
  services.swaync = {
    enable = true;
    style = builtins.readFile ./style.css;
  };
}
