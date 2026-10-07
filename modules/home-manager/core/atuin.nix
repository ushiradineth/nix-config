{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    flags = ["--disable-up-arrow"];
    settings = {
      sync_address = "https://atuin.shupi.ushira.com";
      auto_sync = true;
      sync_frequency = "5m";
      search_mode = "prefix";
      filter_mode = "host";
      style = "compact";
      inline_height = 12;
      show_preview = false;
      show_help = false;
      show_tabs = false;
      enter_accept = false;
    };
  };
}
