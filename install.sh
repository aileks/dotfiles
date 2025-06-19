#!/usr/bin/env bash

set -e

# Get dotdir (this directory)
DOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Symlinks
ln -sf $DOTDIR/tmux/tmux.conf $HOME/.tmux.conf
ln -sf $DOTDIR/zsh/zshrc $HOME/.zshrc

ln -sf $DOTDIR/river $HOME/.config/river
ln -sf $DOTDIR/waybar $HOME/.config/waybar
ln -sf $DOTDIR/rofi $HOME/.config/rofi
ln -sf $DOTDIR/dunst $HOME/.config/dunst
ln -sf $DOTDIR/ghostty $HOME/.config/ghostty
ln -sf $DOTDIR/fastfetch $HOME/.config/fastfetch
ln -sf $DOTDIR/nvim $HOME/.config/nvim
ln -sf $DOTDIR/btop $HOME/.config/btop
ln -sf $DOTDIR/bat $HOME/.config/bat
ln -sf $DOTDIR/cava $HOME/.config/cava

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

echo "Dotfiles installation complete!"
