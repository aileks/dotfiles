#!/usr/bin/env bash

set -e

# Get dotdir (this directory)
DOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Symlinks for home directory files
ln -sf "$DOTDIR/tmux/tmux.conf" "$HOME/.tmux.conf"
ln -sf "$DOTDIR/zsh/zshrc" "$HOME/.zshrc"

# Symlinks for .config directories
CONFIG_DIRS=("zed" "alacritty" "fastfetch" "waybar" "walker" "hypr")

echo "Creating symlinks for .config directories..."
for dir in "${CONFIG_DIRS[@]}"; do
    echo "Setting up $dir"
    rm -rf "$HOME/.config/$dir"
    ln -s "$DOTDIR/$dir" "$HOME/.config/$dir"
done
echo ""

# Install omz
echo "Installing Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Oh My Zsh already installed, skipping..."
fi
echo ""

# Install tpm
echo "Installing tmux package manager"
if [ ! -d "$HOME/.tmux" ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
    echo "Tmux package manager already installed, skipping..."
fi
echo ""

# Install zsh-autosuggestions
echo "Installing zsh-autosuggestions"
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions \
      ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
else
    echo "zsh-autosuggestions already installed, skipping..."
fi
echo ""

# Install fast-syntax-highlighting
echo "Installing fast-syntax-highlighting"
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting" ]; then
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git \
      ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
else
    echo "fast-syntax-highlighting already installed, skipping..."
fi
echo ""
