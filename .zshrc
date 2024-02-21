# Path
export PATH="$PATH:$HOME/.bun/bin:$HOME/.composer/vendor/bin:$HOME/.spicetify:$HOME/.local/bin:$HOME/.config/composer/vendor/bin:$HOME/.cargo/bin:/Applications/WezTerm.app/Contents/MacOS:$HOME/Library/Application Support/Herd/bin/"

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Editor env variables
export EDITOR=nvim
export SUDO_EDITOR=nvim

# Theme
ZSH_THEME="bira"

# Plugins
plugins=(zsh-autosuggestions brew thefuck git fast-syntax-highlighting cp command-not-found sudo)

# OMZ script
source $ZSH/oh-my-zsh.sh

# Aliases
alias ls="eza -lh --color=always --icons --group-directories-first"
alias la="eza -lah --color=always --icons --group-directories-first"
alias lt="eza -aT --color=always --icons --group-directories-first"
alias lh="eza -la --color=always --icons --group-directories-first | grep '^\.'"
alias gs="git status"
alias ga="git add --all"
alias gc="git commit -m"
alias gp="git push"
alias cp="cpv"
alias vim="nvim"
alias ar="php artisan"
alias tailwind="bun add -D prettier prettier-plugin-tailwindcss tailwindcss postcss autoprefixer && bunx tailwindcss init -p"

# NVM
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# bun completions
[ -s "/Users/aileks/.bun/_bun" ] && source "/Users/aileks/.bun/_bun"
