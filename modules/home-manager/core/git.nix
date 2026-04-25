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

      settings = {
        user = {
          name = myvars.userFullname;
          email = myvars.userEmail;
        };
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        pull.rebase = true;
        rerere.enabled = true;
      };

      ignores = [
        "~*"
        ".DS_Store"
        ".direnv/"
        ".agents/"
        ".opencode/"
        ".claude/"
        ".veil/"
        ".lazytf/"
        "node_modules/"
        "dist/"
        "build/"
        "target/"
        "result"
      ];

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

      signing = {
        key = myvars.gpgKeyId;
        signByDefault = true;
      };
    };

    delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        features = "side-by-side";
        diff-so-fancy = true;
        line-numbers = true;
        true-color = "always";
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
          pagers = [
            {
              pager = "delta --dark --paging=never";
              colorArg = "always";
            }
          ];
        };
        os = {
          edit = "nvim {{filename}}";
          editAtLine = "nvim +{{line}} {{filename}}";
          editAtLineAndWait = "nvim --block +{{line}} {{filename}}";
          editInTerminal = true;
          openDirInEditor = "nvim {{dir}}";
        };
        customCommands = [
          {
            key = "G";
            description = "AI commit message";
            context = "files";
            loadingText = "Generating commit message...";
            output = "terminal";
            command = ''
              DIFF=$(git diff --cached --diff-algorithm=minimal)
              if [ -z "$DIFF" ]; then
                DIFF=$(git diff --diff-algorithm=minimal)
              fi
              if [ -z "$DIFF" ]; then
                echo "No changes to commit"
                exit 1
              fi
              MSG=$(echo "$DIFF" | opencode run --agent direct --pure --model "openai/gpt-5.5-fast" "Generate one concise Conventional Commit subject for the provided git diff. Success means the output is only <type>(<scope>): <msg>, uses imperative mood, has no period, stays under 50 characters, and describes the concrete change. If the diff is unclear, choose the safest accurate scope and type without explaining." 2>/dev/null)
              if [ -n "$MSG" ]; then
                git commit -e -m "$MSG"
              fi
            '';
          }
        ];
      };
    };

    gh = {
      enable = true;
    };
  };

  services = {
    gpg-agent = {
      enable = true;
      enableSshSupport = false;
      enableZshIntegration = true;
      defaultCacheTtl = 3600; # 1 hour
      pinentry.package = lib.mkIf pkgs.stdenv.isDarwin pkgs.pinentry_mac; # macOS only
    };
  };
}
