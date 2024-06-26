# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if [[ -f "$HOMEBREW_PREFIX/bin/brew" ]] then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx

# Add in snippets
zinit wait lucid for \
  OMZP::git \
  OMZP::command-not-found \
  as"completion" \
    OMZP::terraform/_terraform \
    OMZ::plugins/docker/completions/_docker \
    OMZP::docker-compose/_docker-compose \
    OMZP::golang/_golang

zinit snippet OMZP::aws

autoload -Uz compinit && compinit
zinit cdreplay -q

source <(kubectl completion zsh)

# To customize prompt, run `p10k configure` or edit ~/dotfiles/.p10k.zsh.
[[ ! -f ~/dotfiles/.p10k.zsh ]] || source ~/dotfiles/.p10k.zsh

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# -----------------------------------------------------------------------------------------------------------------------

# Path

PATH=$PATH:$HOME/.local/bin
PATH=$PATH:$HOME/go/bin

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
alias tfws="terraform workspace select"
alias tfs="terraform state"
alias tfsl="terraform state list"
alias tfv="terraform validate && terraform fmt --recursive && tflint"

alias d='docker'
alias dr='docker run --rm -i -t'

alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias ll="eza -alh --no-time --no-user"
alias tree="eza --tree"

alias cd="z"
alias zz="z -"

alias cat="bat"

alias gc="git checkout"
alias gplo="git pull origin"
alias gpho="git push origin"

# NEOVIM
alias vim="nvim"
alias code="nvim"
alias vi="nvim"
alias nano="nvim"

alias fman="compgen -c | fzf | xargs man"
alias ftldr="compgen -c | fzf | xargs tldr"
alias c='clear'

# -----------------------------------------------------------------------------------------------------------------------

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"
export BAT_THEME=tokyonight_night
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

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
