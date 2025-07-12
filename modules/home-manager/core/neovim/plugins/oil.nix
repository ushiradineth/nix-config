{...}: {
  programs.nixvim.plugins.oil = {
    enable = true;
    settings = {
      default_file_explorer = true;
      delete_to_trash = true;
      columns = ["icon"];
      skip_confirm_for_simple_edits = true;
      view_options = {
        show_hidden = true;
      };
    };
  };

  programs.nixvim.keymaps = [
    {
      key = "-";
      action = ":Oil<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Open Oil";
      };
    }
  ];
}
