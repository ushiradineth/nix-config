_: {
  programs.nixvim.plugins.todo-comments.enable = true;

  programs.nixvim.keymaps = [
    {
      key = "<leader>so";
      action = ":TodoTelescope<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "List all TODOs";
      };
    }
  ];
}
