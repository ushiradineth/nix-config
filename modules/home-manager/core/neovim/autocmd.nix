_: {
  programs.nixvim.autoGroups = {
    FixTerraformCommentString.clear = true;
    CheckExternalChanges.clear = true;
  };

  programs.nixvim.autoCmd = [
    {
      event = ["FocusGained" "BufEnter" "CursorHold" "TermClose" "TermLeave"];
      group = "CheckExternalChanges";
      callback.__raw = ''
        vim.schedule_wrap(function()
          if vim.fn.mode() == "n" and vim.fn.getcmdwintype() == "" then
            vim.cmd.checktime()
          end
        end)
      '';
    }
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
