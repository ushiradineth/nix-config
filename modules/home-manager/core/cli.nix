{
  pkgs,
  lib,
  ...
}: let
  shellAliases = {
    ls = "eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions";
    ll = "eza -alh --no-time --no-user";
    tree = "eza --tree";
    cd = "z";
    zz = "z -";
    cat = "bat";
    c = "clear";
    pip = "pip3";
    fman = "compgen -c | fzf | xargs man";
    ftldr = "compgen -c | fzf | xargs tldr";
    grep = "rg";
    curl = "curlie";
    ndu = "nix-du -s 500MB";
    ntree = "nix-tree";
  };

  FZF_CTRL_T_COMMAND = "fd --hidden --strip-cwd-prefix --exclude .git";
  FZF_CTRL_T_OPTS = ["--preview 'bat -n --color=always --line-range :500 {}'"];
  FZF_DEFAULT_COMMAND = FZF_CTRL_T_COMMAND;
  FZF_DEFAULT_OPTS = FZF_CTRL_T_OPTS;
  FZF_ALT_C_COMMAND = "fd --type=d --hidden --strip-cwd-prefix --exclude .git";
  FZF_ALT_C_OPTS = ["--preview 'eza --tree --color=always {} | head -200'"];
in {
  home.shellAliases = shellAliases;
  home.packages = with pkgs; [
    nvd
    nix-du
    nix-tree
    nix-output-monitor
    nh
  ];
  programs.zsh.shellAliases = shellAliases;
  programs = {
    eza = {
      enable = true;
      enableZshIntegration = true;
      git = true;
      icons = "auto";
      colors = "auto";
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    bat = {
      enable = true;
      themes = {
        tokyonight = {
          src = pkgs.fetchFromGitHub {
            owner = "folke";
            repo = "tokyonight.nvim";
            rev = "45d22cf0e1b93476d3b6d362d720412b3d34465c";
            sha256 = "sha256-TJ/a6N6Cc1T0wdMxMopma1NtwL7rMYbZ6F0zFI1zaIA=";
          };
          file = "extras/sublime/tokyonight_night.tmTheme";
        };
      };
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = FZF_DEFAULT_COMMAND;
      defaultOptions = FZF_DEFAULT_OPTS;
      changeDirWidgetCommand = FZF_ALT_C_COMMAND;
      changeDirWidgetOptions = FZF_ALT_C_OPTS;
      fileWidgetCommand = FZF_CTRL_T_COMMAND;
      fileWidgetOptions = FZF_CTRL_T_OPTS;
    };

    fd = {
      enable = true;
      hidden = false;
      ignores = [
        ".git/*"
        "node_modules/*"
        "__pycache__/*"
        ".next/*"
      ];
    };

    starship = {
      enable = true;
      enableZshIntegration = true;

      settings = {
        format = lib.concatStrings [
          "$sudo"
          "$username"
          "$hostname"
          "$directory"
          "$git_branch"
          "$git_state"
          "$git_status"
          "$character"
        ];
        right_format = lib.concatStrings [
          "$cmd_duration"
        ];
        username = {
          format = "[$user@]($style)";
          show_always = true;
          style_user = "bold blue";
          style_root = "bold red";
        };
        hostname = {
          format = "[$hostname:]($style)";
          ssh_only = false;
          style = "bold blue";
        };
        directory = {
          truncation_length = 255;
          truncate_to_repo = false;
          use_logical_path = false;
          style = "blue";
        };
        git_branch = {
          format = "[$branch]($style)";
          style = "bright-black";
        };
        git_status = {
          format = "[*]($style)[$ahead$diverged$behind](yellow) ";
          style = "bright-black";
          ahead = "⇡$\{count\}";
          diverged = "⇡$\{ahead_count\}⇣$\{behind_count\}";
          behind = "⇣$\{count\}";
        };
        cmd_duration = {
          format = " [$duration]($style)";
          style = "yellow";
        };
      };
    };
  };
}
