_: {
  # Code Navigation
  programs.nixvim.plugins.flash.enable = true;

  programs.nixvim.keymaps = [
    {
      key = "s";
      mode = ["n" "x" "o"];
      action = "<cmd>lua require('flash').jump()<CR>";
      options.desc = "Flash";
    }
  ];
}
