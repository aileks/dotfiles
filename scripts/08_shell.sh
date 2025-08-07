#!/usr/bin/env bash

sudo pacman -S --noconfirm --needed zsh

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
else
    info "Oh My Zsh is already installed."
fi

# Set Zsh as the default shell
if [ "$(basename "$SHELL")" != "zsh" ]; then
    info "Changing default shell to Zsh..."
    if chsh -s "$(which zsh)"; then
        info "Default shell changed to Zsh. Please log out and back in for the change to take effect."
    else
        error "Failed to change shell. Please try running 'chsh -s \$(which zsh)' manually."
    fi
else
    info "Default shell is already Zsh."
fi

info "Zsh setup complete."
