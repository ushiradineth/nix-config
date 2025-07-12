{...}: {
  programs.nixvim.keymaps = [
    # Commenting
    {
      key = "<leader>/";
      mode = ["n"];
      action = "gcc";
      options = {
        remap = true;
        desc = "Toggle comment on current line";
      };
    }
    {
      key = "<leader>/";
      mode = ["v"];
      action = "gc";
      options = {
        remap = true;
        desc = "Toggle comment on selection";
      };
    }

    # Quit
    {
      key = "<leader>qq";
      mode = ["n"];
      action = ":qa!<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Force Quit";
      };
    }
    {
      key = "<leader>wq";
      mode = ["n"];
      action = ":wq!<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Save and Quit";
      };
    }
    {
      key = "<leader>w";
      mode = ["n"];
      action = ":silent w!<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Save";
      };
    }

    # Casing
    {
      key = "<leader>cc";
      mode = ["v"];
      action = ":s/\v_(\w)/\U\1/g<CR>:s/\v(^\l)/\L\1/<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "snake_case to camelCase";
      };
    }
    {
      key = "<leader>cs";
      mode = ["v"];
      action = ":s/\v(\l)(\u)/\1_\l\2/g<CR>:s/\v(^\l)/\L\1/g<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "camelCase to snake_case";
      };
    }

    # Misc
    {
      key = "<leader>lr";
      mode = ["n"];
      action = ":lua vim.wo.relativenumber = not vim.wo.relativenumber; vim.wo.number = true<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Toggle Relative Line Number";
      };
    }
    {
      key = "<leader>lt";
      mode = ["n"];
      action = ":lua vim.wo.number = not vim.wo.number; vim.wo.relativenumber = false<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Toggle Line Number";
      };
    }
    {
      key = "<Leader>lc";
      mode = ["n"];
      action = ":let @+ = expand('%') . ':' . line('.')<cr>";
      options = {
        noremap = true;
        silent = true;
        desc = "Copy file name and the line number";
      };
    }
    {
      key = "<leader>cw";
      mode = ["n"];
      action = ":set wrap!<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Code Wrap";
      };
    }
    {
      key = "<leader>dc";
      mode = ["n"];
      action = ":lua vim.diagnostic.open_float(nil, { focusable = false })<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Current Line Diagnostics";
      };
    }

    # Skip to start/end of line
    {
      key = "<C-a>";
      action = "^";
      mode = ["n" "v"];
      options = {
        noremap = true;
        silent = true;
      };
    }
    {
      key = "<C-e>";
      action = "$";
      mode = ["n" "v"];
      options = {
        noremap = true;
        silent = true;
      };
    }
    {
      key = "<C-a>";
      action = "<C-o>^";
      mode = ["i"];
      options = {
        noremap = true;
        silent = true;
      };
    }
    {
      key = "<C-e>";
      action = "<C-o>$";
      mode = ["i"];
      options = {
        noremap = true;
        silent = true;
      };
    }

    # Skip to start/end of word
    {
      key = "<Esc>b";
      action = "b";
      mode = ["n" "v"];
      options = {
        noremap = true;
        silent = true;
      };
    }
    {
      key = "<Esc>f";
      action = "w";
      mode = ["n" "v"];
      options = {
        noremap = true;
        silent = true;
      };
    }
    {
      key = "<Esc>b";
      action = "<C-o>b";
      mode = ["i"];
      options = {
        noremap = true;
        silent = true;
      };
    }
    {
      key = "<Esc>f";
      action = "<C-o>w";
      mode = ["i"];
      options = {
        noremap = true;
        silent = true;
      };
    }

    # Skip to start/end of WORD (big words)
    {
      key = "\27[1;5D"; # <C-Left>
      action = "B";
      mode = ["n" "v"];
      options = {
        noremap = true;
        silent = true;
      };
    }
    {
      key = "\27[1;5C"; # <C-Right>
      action = "W";
      mode = ["n" "v"];
      options = {
        noremap = true;
        silent = true;
      };
    }
    {
      key = "\27[1;5C"; # <C-Right> in insert
      action = "<C-o>W";
      mode = ["i"];
      options = {
        noremap = true;
        silent = true;
      };
    }
  ];
}
