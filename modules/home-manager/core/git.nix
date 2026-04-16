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
              MSG=$(echo "$DIFF" | opencode run --agent direct --pure --model "opencode/minimax-m2.5-free" "You are a commit message generator. Analyze the provided git diff and output in this format: <type>(<scope>): <msg>. Rules: Use conventional commit format: <type>(<scope>): <msg> (e.g., fix(api): add transactional queries). Imperative mood. No period at end. Max 50 chars. Describe WHAT changed, not why. Be specific. Plain English." 2>/dev/null)
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
