{...}: {
  programs.nixvim.autoGroups = {
    FixTerraformCommentString.clear = true;
  };

  programs.nixvim.autoCmd = [
    {
      event = ["FileType"];
      group = "FixTerraformCommentString";
      callback.__raw = ''
        function(ev)
          vim.bo[ev.buf].commentstring = "# %s"
        end
      '';
      pattern = ["terraform" "hcl"];
    }
  ];
}
