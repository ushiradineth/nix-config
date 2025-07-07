{pkgs, ...}: {
  programs.nixvim.extraPlugins = [
    # Quick open `%s//gcI`
    (pkgs.vimUtils.buildVimPlugin {
      name = "search-replace.nvim";
      src = pkgs.fetchFromGitHub {
        owner = "roobert";
        repo = "search-replace.nvim";
        rev = "main";
        hash = "sha256-hEdEBDeHbJc3efgo7djktX4RemAiX8ZvQlJIEoAgkPM=";
      };
    })
  ];

  programs.nixvim.extraConfigLua = ''
    require("search-replace").setup({
      default_replace_single_buffer_options = "gcI",
    });
  '';

  programs.nixvim.keymaps = [
    {
      key = "<C-r>";
      mode = ["v"];
      action = "<CMD>SearchReplaceWithinVisualSelection<CR>";
      options = {
        noremap = true;
        silent = true;
      };
    }
    {
      key = "<leader>rr";
      mode = ["n"];
      action = "<CMD>SearchReplaceSingleBufferOpen<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Base replace";
      };
    }
    {
      key = "<leader>rw";
      mode = ["n"];
      action = "<CMD>SearchReplaceSingleBufferCWord<CR>";
      options = {
        noremap = true;
        silent = true;
        desc = "Replace hover word";
      };
    }
  ];
}
