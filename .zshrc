# Path
export PATH="$PATH:$HOME/.bun/bin:$HOME/.composer/vendor/bin:$HOME/.spicetify:$HOME/.local/bin:$HOME/.config/composer/vendor/bin:$HOME/.cargo/bin"

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Editor env variables
export EDITOR=nvim
export SUDO_EDITOR=nvim

# Theme
ZSH_THEME="bira"

# Plugins
plugins=(zsh-autosuggestions brew npm composer git fast-syntax-highlighting cp command-not-found sudo macos)

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
alias gp="git push origin main"
alias cp="cpv"
alias vim="nvim"
alias ar="php artisan"
alias gptk="gameportingtoolkit"

# NVM
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
export PATH=$PATH:/home/aileks/.spicetify
export PATH=$PATH:/Users/aileks/.spicetify

# FZF
export FZF_DEFAULT_OPTS="
	--color=fg:#908caa,bg:#232136,hl:#ea9a97
	--color=fg+:#e0def4,bg+:#393552,hl+:#ea9a97
	--color=border:#44415a,header:#3e8fb0,gutter:#232136
	--color=spinner:#f6c177,info:#9ccfd8,separator:#44415a
	--color=pointer:#c4a7e7,marker:#eb6f92,prompt:#908caa"

# Bun completions
[ -s "/Users/aileks/.bun/_bun" ] && source "/Users/aileks/.bun/_bun"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
