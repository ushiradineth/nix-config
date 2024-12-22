{...}: let
  path = "$PATH:$HOME/.local/bin:$HOME/go/bin:$HOME/Library/pnpm";
  envExtra = ''
    export PATH="${path}"
    export EDITOR="nvim"
  '';
  initExtra = ''
    eval "$(kubectl completion zsh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    source /opt/homebrew/share/zsh/site-functions/*

    zstyle ':autocomplete:*' default-context history-incremental-search-backward
    zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
    zstyle ':completion:*' menu no
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
    zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
  '';
in {
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    history = {
      append = true;
      size = 10000;
      save = 10000;
      share = true;
      extended = true;
      expireDuplicatesFirst = true;
      ignoreDups = true;
      ignoreAllDups = true;
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "fzf"
        "kubectl"
        "kubectx"
        "aws"
        "terraform"
        "docker"
        "docker-compose"
        "golang"
      ];
    };

    inherit envExtra initExtra;
  };
}
