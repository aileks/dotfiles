#!/usr/bin/env bash

set -e

# Get dotdir (this directory)
DOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Symlinks
ln -sf $DOTDIR/tmux/tmux.conf $HOME/.tmux.conf
ln -sf $DOTDIR/zsh/zshrc $HOME/.zshrc

rm -rf $HOME/.config/river
ln -s $DOTDIR/river $HOME/.config/river

rm -rf $HOME/.config/waybar
ln -s $DOTDIR/waybar $HOME/.config/waybar

rm -rf $HOME/.config/rofi
ln -s $DOTDIR/rofi $HOME/.config/rofi

rm -rf $HOME/.config/dunst
ln -s $DOTDIR/dunst $HOME/.config/dunst

rm -rf $HOME/.config/alacritty
ln -s $DOTDIR/alacritty $HOME/.config/alacritty

rm -rf $HOME/.config/fastfetch
ln -s $DOTDIR/fastfetch $HOME/.config/fastfetch

rm -rf $HOME/.config/nvim
ln -s $DOTDIR/nvim $HOME/.config/nvim

rm -rf $HOME/.config/btop
ln -s $DOTDIR/btop $HOME/.config/btop

rm -rf $HOME/.config/bat
ln -s $DOTDIR/bat $HOME/.config/bat

rm -rf $HOME/.config/cava
ln -s $DOTDIR/cava $HOME/.config/cava

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
