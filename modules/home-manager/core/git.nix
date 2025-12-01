{
  lib,
  myvars,
  pkgs,
  ...
}: let
  shellAliases = {
    gc = "git checkout";
    gcm = "git commit -s -m";
    gl = "git log --oneline --graph --decorate --all";
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

      userName = myvars.userFullname;
      userEmail = myvars.userEmail;

      includes = [
        {
          condition = "gitdir:~/Code/surge/";
          contents = {
            user.name = myvars.userFullname;
            user.email = myvars.workEmail;
            user.signingKey = myvars.workGpgKeyId;
          };
        }
      ];

      extraConfig = {
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        pull.rebase = true;
        rerere.enabled = true;
      };

      signing = {
        key = myvars.gpgKeyId;
        signByDefault = true;
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
    };

    gpg.enable = true;

    lazygit = {
      enable = true;
      settings = {
        git = {
          overrideGpg = true;
          commit = {
            signOff = true;
          };
          paging = {
            colorArg = "always";
            pager = "delta --dark --paging=never";
          };
        };
        os = {
          edit = "nvim {{filename}}";
          editAtLine = "nvim +{{line}} {{filename}}";
          editAtLineAndWait = "nvim --block +{{line}} {{filename}}";
          editInTerminal = true;
          openDirInEditor = "nvim {{dir}}";
        };
      };
    };

    gh = {
      enable = true;
    };
  };

  services = {
    # GPG agent service for key management
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
      defaultCacheTtl = 3600; # 1 hour
      pinentry.package = lib.mkIf pkgs.stdenv.isDarwin pkgs.pinentry_mac; # macOS only
    };
  };
}
