_: {
  programs.nixvim.plugins.which-key = {
    enable = true;
    settings = {
      replace = {
        desc = [
          [
            "<space>"
            "SPACE"
          ]
          [
            "<leader>"
            "SPACE"
          ]
          [
            "<[cC][rR]>"
            "RETURN"
          ]
          [
            "<[tT][aA][bB]>"
            "TAB"
          ]
          [
            "<[bB][sS]>"
            "BACKSPACE"
          ]
        ];
      };
      spec = [
        {
          __unkeyed-1 = "<leader>c";
          group = "Code";
          icon = "⌨";
        }
        {
          __unkeyed-1 = "<leader>d";
          group = "Diagnostics";
          icon = "⚠";
        }
        {
          __unkeyed-1 = "<leader>g";
          group = "Git";
          icon = "";
        }
        {
          __unkeyed-1 = "<leader>gr";
          group = "Repo";
          icon = "";
        }
        {
          __unkeyed-1 = "<leader>l";
          group = "Line";
          icon = "⋯";
        }
        {
          __unkeyed-1 = "<leader>q";
          group = "Quit";
          icon = "⎋";
        }
        {
          __unkeyed-1 = "<leader>s";
          group = "Search";
          icon = "";
        }
        {
          __unkeyed-1 = "<leader>sw";
          group = "Highlighted Word";
          icon = "";
        }
        {
          __unkeyed-1 = "<leader>w";
          group = "Save";
          icon = "↓";
        }
        {
          __unkeyed-1 = "<leader>r";
          group = "Replace";
          icon = "⇄";
        }
        {
          __unkeyed-1 = "<leader>t";
          group = "Toggle";
          icon = "⇅";
        }
        {
          __unkeyed-1 = "<leader>/";
          group = "Comment";
          icon = "✎";
        }
      ];
    };
  };
}
