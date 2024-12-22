{myvars, ...}: let
  shellAliases = {
    gc = "git checkout";
    lg = "lazygit";
    l = "lazygit";
  };
in {
  home.shellAliases = shellAliases;
  programs.zsh.shellAliases = shellAliases;

  programs = {
    git = {
      enable = true;
      lfs.enable = true;

      userName = myvars.username;
      userEmail = myvars.useremail;

      includes = [
        {
          condition = "gitdir:~/Code/surge";
          contents = {
            user.name = myvars.userfullname;
            user.email = myvars.workemail;
          };
        }
      ];

      extraConfig = {
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        pull.rebase = true;
      };

      delta = {
        enable = true;
        options = {
          features = "side-by-side";
          diff-so-fancy = true;
          line-numbers = true;
          true-color = "always";
        };
      };

      aliases = {
        co = "checkout";
        cm = "commit -m";
        update = "submodule update --init --recursive";
        foreach = "submodule foreach";
      };
    };

    lazygit = {
      enable = true;
      settings = {
        git = {
          paging = {
            colorArg = true;
            pager = "delta --dark --paging=never";
          };
        };
        os = {
          edit = "nvim {{filename}}";
          editAtLine = "nvim --line={{line}} {{filename}}";
          editAtLineAndWait = "nvim --block --line={{line}} {{filename}}";
          editInTerminal = true;
          openDirInEditor = "nvim {{dir}}";
        };
      };
    };
  };
}
