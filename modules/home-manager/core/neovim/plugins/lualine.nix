{...}: let
  oil = {
    sections = {
      lualine_a = [{__raw = "";}];
      lualine_b = [{__raw = "";}];
      lualine_c = [
        {
          __raw = ''
            function()
            	local ok, o = pcall(require, "oil")
            	if ok then
            		return vim.fn.fnamemodify(o.get_current_dir(), ":~")
            	else
            		return ""
            	end
            end
          '';
        }
      ];
      lualine_x = [{__raw = "";}];
      lualine_y = [{__raw = "";}];
      lualine_z = [{__raw = "";}];
    };
    filetypes = ["oil"];
  };
  conditions = {
    buffer_not_empty = {
      __raw = ''
        function()
          return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
        end
      '';
    };
    hide_in_width = {
      __raw = ''
        function()
          return vim.fn.winwidth(0) > 80
        end
      '';
    };
  };
in {
  programs.nixvim.plugins.lualine = {
    enable = true;
    settings = {
      options = {
        component_separators = "";
        section_separators = "";
        theme = "auto";
      };

      sections = {
        # Keep these empty to disable them
        lualine_a = [{__raw = "";}];
        lualine_b = [{__raw = "";}];
        lualine_y = [{__raw = "";}];
        lualine_z = [{__raw = "";}];

        # Left side
        lualine_c = [
          {
            __unkeyed-1 = "mode";
            cond = conditions.buffer_not_empty;
          }

          {
            __unkeyed-1 = "filename";
            file_status = true;
            path = 1;
            cond = conditions.buffer_not_empty;
            color = {fg = "#e2bdbc";};
          }

          {
            __unkeyed-1 = "diagnostics";
            cond = conditions.buffer_not_empty;
            sources = ["nvim_diagnostic"];
            sections = ["error" "warn" "info" "hint"];
            symbols = {
              error = " ";
              warn = " ";
              info = " ";
              hint = " ";
            };
            update_in_insert = false;
          }
        ];

        # Right side
        lualine_x = [
          {
            __unkeyed-1 = "location";
          }
          {
            __unkeyed-1 = "lsp_status";
            ignore_lsp = ["diagnosticls" "typos_lsp"];
            icon = "";
            symbols = {done = "";};
          }

          {
            __unkeyed-1 = "diff";
            cond = conditions.hide_in_width;
            symbols = {
              added = " ";
              modified = "󰝤 ";
              removed = " ";
            };
          }

          {
            __unkeyed-1 = "branch";
            icon = "";
            color = {fg = "#e3a27d";};
          }
        ];
      };

      extensions = ["mason" "lazy" "trouble" oil];
    };
  };
}
