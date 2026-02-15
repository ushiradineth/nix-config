_: {
  programs.nixvim.plugins.transparent = {
    enable = true;
    luaConfig = {
      post = ''
        require("transparent").clear_prefix("lualine")
      '';
    };
    settings = {
      groups = [
        "Normal"
        "NormalNC"
        "Comment"
        "Constant"
        "Special"
        "Identifier"
        "Statement"
        "PreProc"
        "Type"
        "Underlined"
        "Todo"
        "String"
        "Function"
        "Conditional"
        "Repeat"
        "Operator"
        "Structure"
        "LineNr"
        "NonText"
        "SignColumn"
        "CursorLine"
        "CursorLineNr"
        "StatusLine"
        "StatusLineNC"
        "EndOfBuffer"
        "ZenBg"
      ];
      extra_groups = [
        # "NormalFloat"
        "FloatBorder"
        "FloatTitle"
        "NvimTreeNormal"
        "NvimTreeNormalNC"
        "TelescopeNormal"
        "TelescopeBorder"
        "TelescopePromptNormal"
        "TelescopePromptBorder"
        "TelescopeResultsNormal"
        "TelescopeResultsBorder"
        "TelescopePreviewNormal"
        "TelescopePreviewBorder"
      ];
    };
  };

  programs.nixvim.colorschemes.catppuccin = {
    enable = true;
    settings.flavour = "frappe";
  };

  programs.nixvim.extraConfigLua = ''
    local ui_groups = {
      CursorLineNr = { fg = "#f0e7fa", bold = true },
      WinSeparator = { fg = "#ad95b8" },
      Visual = { bg = "#5a6787" },
      NormalFloat = { bg = "#3e4760", fg = "#f6f3fb" },
      FloatBorder = { fg = "#c1aed0" },
      FloatTitle = { fg = "#d6c7df", bold = true },
      Pmenu = { bg = "#3e4760", fg = "#f6f3fb" },
      PmenuSel = { bg = "#4b5671", fg = "#f6f3fb", bold = true },
      TelescopeNormal = { bg = "#3e4760", fg = "#f6f3fb" },
      TelescopeBorder = { fg = "#6b7897", bg = "#3e4760" },
      TelescopePromptNormal = { bg = "#4b5671", fg = "#f6f3fb" },
      TelescopePromptBorder = { fg = "#c1aed0", bg = "#4b5671" },
      TelescopeResultsNormal = { bg = "#3e4760", fg = "#f6f3fb" },
      TelescopeResultsBorder = { fg = "#6b7897", bg = "#3e4760" },
      TelescopePreviewNormal = { bg = "#3e4760", fg = "#f6f3fb" },
      TelescopePreviewBorder = { fg = "#6b7897", bg = "#3e4760" },
      TroubleNormal = { bg = "#3e4760", fg = "#f6f3fb" },
      TroubleNormalNC = { bg = "#3e4760", fg = "#f6f3fb" },
      WhichKeyFloat = { bg = "#3e4760", fg = "#f6f3fb" },
      LazyNormal = { bg = "#3e4760", fg = "#f6f3fb" },
      MasonNormal = { bg = "#3e4760", fg = "#f6f3fb" },
    }

    local function apply_pastel_purple_ui()
      for group, style in pairs(ui_groups) do
        vim.api.nvim_set_hl(0, group, style)
      end
    end

    vim.api.nvim_create_autocmd("ColorScheme", {
      pattern = "*",
      callback = apply_pastel_purple_ui,
    })

    apply_pastel_purple_ui()
  '';

  programs.nixvim.keymaps = [
    {
      key = "<leader>tt";
      action = ":TransparentToggle<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Toggle Transparency";
      };
    }
  ];
}
