# Setup zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

# -----------------------------------------------------------------------------------------------------------------------

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::aws
zinit snippet OMZP::terraform/_terraform
zinit snippet OMZ::plugins/docker/completions/_docker
zinit snippet OMZP::docker-compose/_docker-compose
zinit snippet OMZP::golang/_golang

autoload -Uz compinit && compinit
zinit cdreplay -q

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# -----------------------------------------------------------------------------------------------------------------------

# Path

PATH=$PATH:$HOME/.local/bin
PATH=$PATH:$HOME/go/bin
PATH=$PATH:$HOME/Library/pnpm

export PATH=$PATH

# -----------------------------------------------------------------------------------------------------------------------

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# -----------------------------------------------------------------------------------------------------------------------

# Aliases

alias tf="terraform"
alias tfw="terraform workspace"
alias tfv="terraform validate && terraform fmt --recursive && tflint"

alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias ll="eza -alh --no-time --no-user"
alias tree="eza --tree"

alias cd="z"
alias zz="z -"

alias cat="bat"

# Git
alias gc="git checkout"

# NEOVIM
alias vim="nvim"
alias code="nvim"
alias vi="nvim"
alias nano="nvim"
alias n="nvim"
alias nv="nvim"

# Lazygit
alias l="lazygit"
alias lg="lazygit"

# Lazydocker
alias d="lazydocker"
alias ld="lazydocker"

alias fman="compgen -c | fzf | xargs man"
alias ftldr="compgen -c | fzf | xargs tldr"
alias c="clear"
alias pip="pip3"

# -----------------------------------------------------------------------------------------------------------------------

# Shell integrations
eval "$(starship init zsh)"
eval "$(kubectl completion zsh)"
eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
source /opt/homebrew/share/zsh/site-functions/*

# -----------------------------------------------------------------------------------------------------------------------

# Environment variables
export BAT_THEME=tokyonight_night
export NVM_DIR="$HOME/.nvm"
export STARSHIP_CONFIG="$HOME/dotfiles/.config/starship/starship.toml"
export MINIKUBE_HOME="$HOME/.config/minikube"
export K9S_CONFIG_DIR="$HOME/dotfiles/.config/k9s" # config does not load on symlinks
export LG_CONFIG_FILE="$HOME/dotfiles/.config/lazygit/config.yml"
export UID=$(id -u)
export GID=$(id -g)
export EDITOR=nvim

# -----------------------------------------------------------------------------------------------------------------------

# FZF and FD configuration
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

## Use fd (https://github.com/sharkdp/fd) for listing path candidates.
## The first argument to the function ($1) is the base path to start traversal
## See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

#E Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

## Advanced customization of fzf options via _fzf_comprun function
## The first argument to the function is the name of the command.
## You should make sure to pass the rest of the arguments to fzf.

_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo $'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "bat -n --color=always --line-range :500 {}" "$@" ;;
  esac
}

nvim() {
  if [[ "$1" == "." && "$#" -eq 1 ]]; then
      command nvim
  else
      command nvim "$@"
  fi
}
