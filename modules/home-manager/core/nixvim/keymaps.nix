{...}: {
  programs.nixvim.keymaps = [
    {
      action = "<cmd>Oil<CR>";
      key = "-";
    }
  ];
}
