{...}: {
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
    {
      key = "<leader>rs";
      mode = ["n"];
      action = ":Spectre<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Open Spectre";
      };
    }
    {
      key = "<A-Down>";
      mode = ["n" "v"];
      action = ":MoveLine(1)<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Move line down";
      };
    }
    {
      key = "<A-Up>";
      mode = ["n" "v"];
      action = ":MoveLine(-1)<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Move line up";
      };
    }
    {
      key = "<leader>dd";
      action = ":Trouble diagnostics toggle<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Diagnostics";
      };
    }
    {
      key = "<leader>dD";
      action = ":Trouble diangostics toggle filter.bug=0<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Buffer Diagnostics";
      };
    }
    {
      key = "<leader>tm";
      action = ":Markview Toggle<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Toggle Markdown Preview";
      };
    }
  ];
}
