_: {
  programs.nixvim = {
    plugins = {
      gitsigns = {
        enable = true;
        settings = {
          attach_to_untracked = true;
          current_line_blame = true;
          signcolumn = true;
          watch_gitdir = {
            follow_files = true;
          };
        };
      };
      snacks = {
        enable = true;
        settings.picker = {
          enabled = true;
          ui_select = false;
          layout.preset = "default";
          previewers.diff.style = "syntax";
          win = {
            input.keys."<Esc>" = {
              __unkeyed-1 = "close";
              mode = ["n" "i"];
            };
            list.keys."<Esc>" = "close";
            preview.keys."<Esc>" = "close";
          };
          sources = {
            # History is for review, not the picker's default checkout action.
            git_log.confirm = "close";
          };
        };
      };
    };

    keymaps = [
      {
        key = "<leader>gp";
        mode = ["n"];
        action = ":Gitsigns preview_hunk_inline<CR>";
        options = {
          noremap = true;
          silent = true;
          desc = "Preview Hunk Inline";
        };
      }
      {
        key = "]c";
        mode = ["n"];
        action.__raw = ''
          function()
            if vim.wo.diff then
              vim.cmd.normal({ vim.v.count1 .. ']c', bang = true })
            else
              require('gitsigns').nav_hunk('next', { target = 'all' })
            end
          end
        '';
        options = {
          silent = true;
          desc = "Next Hunk";
        };
      }
      {
        key = "[c";
        mode = ["n"];
        action.__raw = ''
          function()
            if vim.wo.diff then
              vim.cmd.normal({ vim.v.count1 .. '[c', bang = true })
            else
              require('gitsigns').nav_hunk('prev', { target = 'all' })
            end
          end
        '';
        options = {
          silent = true;
          desc = "Previous Hunk";
        };
      }
      {
        key = "<leader>gs";
        mode = ["n" "x"];
        action = ":Gitsigns stage_hunk<CR>";
        options = {
          silent = true;
          desc = "Stage / Unstage Hunk or Selected Lines";
        };
      }
      {
        key = "<leader>gh";
        mode = ["n"];
        action = ":lua Snacks.picker.git_log()<CR>";
        options = {
          noremap = true;
          silent = true;
          desc = "Repository Commits / History";
        };
      }
    ];
  };
}
