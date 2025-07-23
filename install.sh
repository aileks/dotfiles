#!/usr/bin/env bash

set -e

# Get dotdir (this directory)
DOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Symlinks
ln -sf $DOTDIR/tmux/tmux.conf $HOME/.tmux.conf
ln -sf $DOTDIR/zsh/zshrc $HOME/.zshrc

rm -rf $HOME/.config/ghostty
ln -s $DOTDIR/ghostty $HOME/.config/ghostty

# rm -rf $HOME/.config/fastfetch
# ln -s $DOTDIR/fastfetch $HOME/.config/fastfetch

# rm -rf $HOME/.config/nvim
# ln -s $DOTDIR/nvim $HOME/.config/nvim

# rm -rf $HOME/.config/cava
# ln -s $DOTDIR/cava $HOME/.config/cava

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
