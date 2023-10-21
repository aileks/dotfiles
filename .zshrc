# Path
export PATH="$PATH:$HOME/.cargo/bin:$HOME/.spicetify:$HOME/.local/bin:$HOME/.config/composer/vendor/bin"

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Editor env variables
export EDITOR=nvim
export SUDO_EDITOR=nvim

# Theme
ZSH_THEME="bira"

# Plugins
plugins=(zsh-autosuggestions npm composer git suse fast-syntax-highlighting cp command-not-found colorize)

# OMZ script
source $ZSH/oh-my-zsh.sh

# Aliases
alias ls="eza -lh --color=always --icons --group-directories-first"
alias la="eza -lah --color=always --icons --group-directories-first"
alias lt="eza -aT --color=always --icons --group-directories-first"
alias lh="eza -la --color=always --icons --group-directories-first | grep '^\.'"
alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push origin main"
alias cp="cpv"

# NVM
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
