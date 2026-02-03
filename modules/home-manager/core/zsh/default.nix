{
  pkgs,
  lib,
  ...
}: let
  path = "$PATH:$HOME/.local/bin:$HOME/go/bin:$HOME/Library/pnpm:$HOME/.cargo/bin";
  envExtra = ''
    export PATH="${path}"
    export EDITOR="nvim"
    export SHELL="${pkgs.zsh}/bin/zsh"
  '';
  conditionalInitContent =
    if pkgs.stdenv.isDarwin
    then ''
      eval "$(/opt/homebrew/bin/brew shellenv)"

      # nvm initialization
      export NVM_DIR="$HOME/.nvm"
      [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
      [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
    ''
    else "";
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
        "gcloud"
        "rust"
        "helm"
      ];
    };

    envExtra = envExtra;
    initContent = ''
      ${conditionalInitContent}

      zstyle ':autocomplete:*' default-context history-incremental-search-backward
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      zstyle ':completion:*' menu no
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

      bindkey -s '^As' 't\n'

      ${lib.fileContents ./sessionizer.zsh}
    '';
  };
}
