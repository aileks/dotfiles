#!/usr/bin/env bash

sudo pacman -S --noconfirm --needed zsh

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
fi

if [ "$(basename "$SHELL")" != "zsh" ]; then
    chsh -s "$(which zsh)"
fi
