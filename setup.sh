#!/usr/bin/env bash

set -e

# Get dotdir (this directory)
DOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Symlinks
ln -sf $DOTDIR/tmux/tmux.conf $HOME/.tmux.conf
ln -sf $DOTDIR/zsh/zshrc $HOME/.zshrc
ln -sf $DOTDIR/.Xresources $HOME/.Xresources

rm -rf $HOME/.config/hypr
ln -s $DOTDIR/hypr $HOME/.config/hypr

rm -rf $HOME/.config/dunst
ln -s $DOTDIR/dunst $HOME/.config/dunst

rm -rf $HOME/.config/rofi
ln -s $DOTDIR/rofi $HOME/.config/rofi

rm -rf $HOME/.config/ghostty
ln -s $DOTDIR/ghostty $HOME/.config/ghostty

rm -rf $HOME/.config/fastfetch
ln -s $DOTDIR/fastfetch $HOME/.config/fastfetch

rm -rf $HOME/.config/waybar
ln -s $DOTDIR/waybar $HOME/.config/waybar

# Zed is a special case
ln -sf $DOTDIR/zed/keymap.json $HOME/.config/zed/keymap.json
ln -sf $DOTDIR/zed/settings.json $HOME/.config/zed/settings.json
rm -rf $HOME/.config/zed/snippets
ln -s $DOTDIR/zed/snippets $HOME/.config/zed/snippets

# Copy utils
echo "Copying utils..."
if [ -d "$HOME/.local/bin" ]; then
    cp -r ./utils/* $HOME/.local/bin
    echo "Files copied successfully to $HOME/.local/bin"
else
    echo "$HOME/.local/bin directory does not exist. Creating it..."
    mkdir -p "$HOME/.local/bin"
    cp -r ./utils/* "$HOME/.local/bin"
    echo "Files copied successfully to newly created $HOME/.local/bin"
fi
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

echo "Dotfiles copied successfully!"
