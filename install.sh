#!/usr/bin/env bash

set -e

RESET='\033[0m'
INFO='\033[0;32m'
WARN='\033[0;33m'
ERROR='\033[0;31m'
QUESTION='\033[0;36m'

info() {
    echo -e "${INFO}INFO: $1${RESET}"
}

warn() {
    echo -e "${WARN}WARN: $1${RESET}"
}

error() {
    echo -e "${ERROR}ERROR: $1${RESET}" >&2
    exit 1
}

question() {
    echo -e "${QUESTION}INPUT: $1${RESET}"
}

info "Starting dotfiles setup..."

info "Updating system packages..."
sudo pacman -Syu --noconfirm

info "Running setup scripts..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts"

for script in "$SCRIPT_DIR"/*.sh; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        info "Executing $(basename "$script")..."
        "$script"
    else
        warn "Skipping non-executable or non-existent script: $script"
    fi
done

info "Creating symbolic links..."
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILES=(
    "alacritty"
    "fastfetch"
    "fontconfig"
    "hypr"
    "mako"
    "nvim"
    "tmux/tmux.conf"
    "walker"
    "waybar"
    "zed/keymap.json"
    "zed/settings.json"
    "zsh/zshrc"
)

for config in "${CONFIG_FILES[@]}"; do
    source_path="$DOTFILES_DIR/$config"
    if [ "$config" == "zsh/zshrc" ]; then
        target_path="$HOME/.zshrc"
    elif [ "$config" == "tmux/tmux.conf" ]; then
        target_path="$HOME/.tmux.conf"
    elif [ "$config" == "zed/keymap.json" ]; then
        target_path="$HOME/.config/zed/keymap.json"
    elif [ "$config" == "zed/settings.json" ]; then
        target_path="$HOME/.config/zed/settings.json"
    else
        target_path="$HOME/.config/$(basename "$config")"
    fi

    if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
        info "Backing up existing config: $target_path"
        mv "$target_path" "$target_path.bak"
    fi

    mkdir -p "$(dirname "$target_path")"

    if [ ! -L "$target_path" ]; then
        info "Creating symlink for $config..."
        ln -sf "$source_path" "$target_path"
    else
        info "Symlink for $config already exists."
    fi
done

info "Copying local utilities..."
BIN_DIR="$DOTFILES_DIR/bin"
LOCAL_BIN_DIR="$HOME/.local/bin"

mkdir -p "$LOCAL_BIN_DIR"

for script in "$BIN_DIR"/*.sh; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        target_path="$LOCAL_BIN_DIR/$(basename "$script" .sh)"
        if [ ! -L "$target_path" ]; then
            info "Copying $(basename "$script")..."
            cp "$script" "$target_path"
        else
            info "$(basename "$script") already exists."
        fi
    fi
done

question "System setup is complete. It is highly recommended to reboot now. Reboot? (y/N)"
read -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    info "Rebooting now..."
    sudo reboot
else
    info "Skipping reboot. Please remember to reboot your system later to apply all changes."
fi
