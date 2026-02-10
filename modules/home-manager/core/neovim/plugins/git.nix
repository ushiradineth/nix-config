_: {
  programs.nixvim = {
    plugins = {
      gitsigns = {
        enable = true;
        settings = {
          current_line_blame = true;
          signcolumn = true;
          watch_gitdir = {
            follow_files = true;
          };
        };
      };
      diffview.enable = true;
    };

    keymaps = [
      {
        key = "<leader>gp";
        mode = ["n"];
        action = ":Gitsigns preview_hunk<CR>";
        options = {
          noremap = true;
          silent = true;
          desc = "Preview Hunk";
        };
      }
      {
        key = "<leader>gd";
        mode = ["n"];
        action = ":DiffviewOpen -- %<CR>";
        options = {
          noremap = true;
          silent = true;
          desc = "Diff";
        };
      }
      {
        key = "<leader>gdc";
        mode = ["n"];
        action = ":DiffviewClose<CR>";
        options = {
          noremap = true;
          silent = true;
          desc = "Diff Close";
        };
      }
      {
        key = "<leader>grd";
        mode = ["n"];
        action = ":DiffviewOpen<CR>";
        options = {
          noremap = true;
          silent = true;
          desc = "Diff";
        };
      }
      {
        key = "<leader>gh";
        mode = ["n"];
        action = ":DiffviewFileHistory %<CR>";
        options = {
          noremap = true;
          silent = true;
          desc = "History";
        };
      }
      {
        key = "<leader>grh";
        mode = ["n"];
        action = ":DiffviewFileHistory<CR>";
        options = {
          noremap = true;
          silent = true;
          desc = "History";
        };
      }
    ];
  };
}
