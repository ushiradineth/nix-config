{...}: {
  programs.nixvim.plugins.alpha = {
    enable = true;

    layout = [
      {
        type = "padding";
        val = 2;
      }

      {
        type = "text";
        val = [
          "                                  __                  "
          "     ___     ___    ___   __  __ /\\_\\    ___ ___      "
          "    / _ `\\  / __`\\ / __`\\/\\ \\/\\ \\\\/\\ \\  / __` __`\\    "
          "   /\\ \\/\\ \\/\\  __//\\ \\_\\ \\ \\ \\_/ |\\ \\ \\/\\ \\/\\ \\/\\ \\   "
          "   \\ \\_\\ \\_\\ \\____\\ \\____/\\ \\___/  \\ \\_\\ \\_\\ \\_\\ \\_\\  "
          "    \\/_/\\/_/\\/____/\\/___/  \\/__/    \\/_/\\/_/\\/_/\\/_/  "
        ];
        opts = {
          hl = "Type";
          position = "center";
        };
      }

      {
        type = "padding";
        val = 2;
      }

      {
        type = "group";
        val = [
          {
            type = "text";
            val = "Recent files";
            opts = {
              hl = "SpecialComment";
              position = "center";
            };
          }
          {
            type = "padding";
            val = 1;
          }

          {
            type = "group";
            val = {__raw = "function() return { require('alpha.themes.theta').mru(0, vim.fn.getcwd()) } end";};
            opts = {shrink_margin = false;};
          }
        ];
      }

      {
        type = "padding";
        val = 2;
      }

      {
        type = "group";
        position = "center";
        val = let
          mkButton = shortcut: cmd: val: hl: {
            type = "button";
            inherit val;
            opts = {
              inherit hl shortcut;
              keymap = [
                "n"
                shortcut
                cmd
                {}
              ];
              position = "center";
              cursor = 0;
              width = 50;
              align_shortcut = "right";
              hl_shortcut = "Keyword";
            };
          };
        in [
          {
            type = "text";
            val = "Quick links";
            opts = {
              hl = "SpecialComment";
              position = "center";
            };
          }
          {
            type = "padding";
            val = 2;
          }
          (
            mkButton
            "e"
            "<CMD>ene<CR>"
            "New File"
            "Operator"
          )
          (
            mkButton
            "f"
            "<CMD>Telescope find_files<CR>"
            "Find File"
            "Operator"
          )
          (
            mkButton
            "s"
            "<CMD>Telescope live_grep<CR>"
            "Find in Workspace"
            "Operator"
          )
          (
            mkButton
            "r"
            "<CMD>require('spectre').open()<CR>"
            "Search & Replace"
            "Operator"
          )
          (
            mkButton
            "u"
            "<CMD>Lazy sync<CR>"
            "Update Plugins"
            "Operator"
          )
          (
            mkButton
            "q"
            "<CMD>qa<CR>"
            "Quit Neovim"
            "Operator"
          )
        ];
      }
    ];
  };
}
