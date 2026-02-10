_: {
  programs.nixvim.plugins = {
    cmp = {
      enable = true;
      autoEnableSources = true;
      settings = {
        window = {};
        experimental = {
          ghost_text = false;
        };

        snippet = {
          expand = "function(args) require('luasnip').lsp_expand(args.body) end";
        };

        completion = {
          completeopt = "menu,noinsert,noselect";
        };

        mapping = {
          "<Up>" = "cmp.mapping.select_prev_item()";
          "<Down>" = "cmp.mapping.select_next_item()";
          "<Left>" = "cmp.mapping.select_prev_item()";
          "<Right>" = "cmp.mapping.select_next_item()";
          "<C-c>" = "cmp.mapping.complete()";
          "<C-e>" = "cmp.mapping.close()";
          "<CR>" = ''
            cmp.mapping(function(fallback)
              -- returns true if the character under the cursor is whitespace.
              local is_whitespace = function()
                local col = vim.fn.col(".") - 1
                if col <= 0 then
                  return true
                end

                local line = vim.fn.getline(".")
                local char_under_cursor = string.sub(line, col, col)

                return string.match(char_under_cursor, "%s") ~= nil
              end

              -- uses treesitter to determine if cursor is currently hovering over a comment.
              local is_comment = function()
                local context = require("cmp.config.context")
                return context.in_treesitter_capture("comment") == true or context.in_syntax_group("Comment")
              end

              if cmp.visible() and not is_whitespace() and not is_comment() then
                cmp.confirm({
                  behavior = cmp.ConfirmBehavior.Replace,
                  select = true,
                })
              else
                fallback()
              end
            end, { "i", "s" })
          '';
        };

        sources = [
          {name = "path";}
          {name = "nvim_lsp";}
          {name = "nvim_lsp_signature_help";}
          {
            name = "nvim_lua";
            keyword_length = 2;
          }
          {
            name = "buffer";
            keyword_length = 3;
          }
          {
            name = "luasnip";
            keyword_length = 2;
          }
        ];

        formatting = {
          format = ''
            function(entry, item)
               local abbrev = {
                 path = "PATH",
                 nvim_lsp = "LSP",
                 nvim_lsp_signature_help = "LSP",
                 nvim_lua = "LUA",
                 buffer = "BUF",
                 luasnip = "SNIP",
                 calc = "CALC",
                 cmdline = "CMD",
               }
               item.menu = "[" .. abbrev[entry.source.name] .. "]"
               return item
             end
          '';
        };
      };

      cmdline = {
        ":" = {
          mapping.__raw = "cmp.mapping.preset.cmdline({})";
          sources = [{name = "cmdline";}];
        };
        "/" = {
          mapping.__raw = "cmp.mapping.preset.cmdline({})";
          completion.autocomplete = false;
          sources = [{name = "buffer";}];
        };
        "?" = {
          mapping.__raw = "cmp.mapping.preset.cmdline({})";
          completion.autocomplete = false;
          sources = [{name = "buffer";}];
        };
      };
    };

    cmp-buffer.enable = true;
    cmp-cmdline.enable = true;
    cmp-path.enable = true;
    cmp-nvim-lsp.enable = true;
    cmp-nvim-lsp-signature-help.enable = true;
    cmp-nvim-lua.enable = true;
    luasnip.enable = true;
    cmp_luasnip.enable = true;
    friendly-snippets.enable = true;
  };
}
