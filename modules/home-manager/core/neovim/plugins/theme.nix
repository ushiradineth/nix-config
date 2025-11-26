{...}: {
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
