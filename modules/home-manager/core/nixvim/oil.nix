{...}: {
  programs.nixvim.plugins.oil = {
    enable = true;
    settings = {
      default_file_explorer = true;
      delete_to_trash = true;
      # columns = [
      #   "icon",
      #   # -- "permissions",
      #   # -- "size",
      #   # -- "mtime",
      # ];
      view_options = {
        show_hidden = true;
      };
    };
  };
}
