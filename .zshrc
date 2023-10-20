# Path
export PATH="$PATH:$HOME/.cargo/bin:$HOME/.config/emacs/bin:$HOME/.spicetify:$HOME/.local/bin:$HOME/.local/bin/zig:$HOME/.config/composer/vendor/bin"

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Sudoedit
# export EDITOR=helix

# Theme
ZSH_THEME="bira"

# Plugins
plugins=(git dnf fast-syntax-highlighting cp command-not-found colorize rust)

# OMZ script
source $ZSH/oh-my-zsh.sh

# Aliases
alias ls="exa -lh --color=always --icons --group-directories-first"
alias la="exa -lah --color=always --icons --group-directories-first"
alias lt="exa -aT --color=always --icons --group-directories-first"
alias lh="exa -la --color=always --icons --group-directories-first | grep '^\.'"
alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push origin main"
alias cp="cpv"
alias nfetch="nerdfetch"

# NVM
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
