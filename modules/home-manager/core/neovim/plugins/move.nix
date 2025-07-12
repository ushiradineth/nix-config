{pkgs, ...}: {
  # Move code blocks
  programs.nixvim.extraPlugins = [
    (pkgs.vimUtils.buildVimPlugin {
      name = "move.nvim";
      src = pkgs.fetchFromGitHub {
        owner = "fedepujol";
        repo = "move.nvim";
        rev = "v2.0.0";
        hash = "sha256-aJi7r9yPdQyH6i8EtQzKdRhEQ3SLz32oqcN0tf2qRZA=";
      };
    })
  ];

  programs.nixvim.extraConfigLua = ''
    require('move').setup({});
  '';

  programs.nixvim.keymaps = [
    {
      key = "<A-Down>";
      mode = ["n"];
      action = ":MoveLine(1)<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Move line down";
      };
    }
    {
      key = "<A-Up>";
      mode = ["n"];
      action = ":MoveLine(-1)<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Move line up";
      };
    }
    {
      key = "<A-Down>";
      mode = ["v"];
      action = ":MoveBlock(1)<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Move block down";
      };
    }
    {
      key = "<A-Up>";
      mode = ["v"];
      action = ":MoveBlock(-1)<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Move block up";
      };
    }
  ];
}
