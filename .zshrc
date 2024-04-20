# P10k and OMZ init

## Check if the zsh configuration file for the Powerlevel10k instant prompt exists and is readable.
## If it does, source the file to incorporate its configurations into the current shell environment.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH=$HOME/.oh-my-zsh
source $ZSH/oh-my-zsh.sh

## Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
## Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
plugins=(git kubectl docker zsh-completions)

source "$HOMEBREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme"

## To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
ZSH_THEME="powerlevel10k/powerlevel10k"

## Update automatically without asking
zstyle ':omz:update' mode auto

## Enable command auto-correction
ENABLE_CORRECTION="true"

## Display red dots whilst waiting for completion
COMPLETION_WAITING_DOTS="true"

## Reload the zsh-completions
autoload -U compinit && compinit
eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source <(kubectl completion zsh)

## Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

## Android Studio
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$HOME/Android/Sdk

## Init Zoxide (better cd)
eval "$(zoxide init zsh)"

## Init fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# -----------------------------------------------------------------------------------------------------------------------

# Path

PATH=$PATH:$HOME/.local/bin
PATH=$PATH:$HOME/go/bin
PATH=$PATH:$HOME/.dotnet/tools
PATH=$PATH:$ANDROID_HOME/tools
PATH=$PATH:$ANDROID_HOME/platform-tools
PATH=$PATH:$HOMEBREW_PREFIX/opt/postgresql@15/bin

export PATH=$PATH

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

alias ntcd="open . -a iterm"
alias vim="nvim"
