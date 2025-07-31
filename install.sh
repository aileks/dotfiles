#!/usr/bin/env bash

set -e

DOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTDIR/scripts/common.sh"

check_ubuntu() {
    if ! grep -q "Ubuntu" /etc/os-release; then
        print_error "This script is designed for Ubuntu Linux."
        exit 1
    fi
}

update_system() {
    if prompt_user "Update system packages?" "y"; then
        sudo apt update && sudo apt upgrade -y
        print_success "System updated"
    else
        print_warning "Skipping system update..."
    fi
}

install_packages() {
    print_header "Package Installation"

    if prompt_user "Would you like to install general packages?" "n"; then
        bash "$DOTDIR/scripts/packages.sh"
    else
        print_warning "Skipping general package installation..."
    fi

    if prompt_user "Would you like to install development tools?" "n"; then
        bash "$DOTDIR/scripts/dev-tools.sh"
    else
        print_warning "Skipping development tools installation..."
    fi

    if command -v gh &> /dev/null && prompt_user "Log in with GitHub CLI?" "y"; then
        gh auth login
    fi
}

setup_dotfiles() {
    print_header "Setting Up Dotfiles"

    print_info "Creating symlinks for dotfiles..."
    for file in ".tmux.conf" ".zshrc"; do
        if [[ -f "$HOME/$file" && ! -L "$HOME/$file" ]]; then
            print_warning "Backing up existing $file to ${file}.bak"
            mv "$HOME/$file" "$HOME/${file}.bak"
        fi
    done

    mkdir -p "$HOME"
    ln -sf "$DOTDIR/tmux/tmux.conf" "$HOME/.tmux.conf"
    print_success "Linked tmux.conf"
    ln -sf "$DOTDIR/zsh/zshrc" "$HOME/.zshrc"
    print_success "Linked zshrc"

    CONFIG_DIRS=("ghostty" "zed" "fastfetch")
    print_info -e "\nCreating symlinks for .config directories..."
    mkdir -p "$HOME/.config"
    for dir in "${CONFIG_DIRS[@]}"; do
        if [[ -d "$HOME/.config/$dir" && ! -L "$HOME/.config/$dir" ]]; then
            print_warning "Backing up existing .config/$dir to .config/${dir}.bak"
            mv "$HOME/.config/$dir" "$HOME/.config/${dir}.bak"
        fi
        rm -rf "$HOME/.config/$dir"
        ln -s "$DOTDIR/$dir" "$HOME/.config/$dir"
        print_success "Linked $dir config"
    done
}

install_omz() {
    print_header "Installing Oh My Zsh"

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        print_success "Oh My Zsh installed"
    else
        print_warning "Oh My Zsh already installed, skipping..."
    fi
}

install_tpm() {
    print_header "Installing Tmux Package Manager"

    if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
        mkdir -p "$HOME/.tmux/plugins"
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
        print_success "Tmux package manager installed"
    else
        print_warning "Tmux package manager already installed, skipping..."
    fi
}

install_zsh_plugins() {
    print_header "Installing Zsh Plugins"

    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions \
          "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
        print_success "zsh-autosuggestions installed"
    else
        print_warning "zsh-autosuggestions already installed, skipping..."
    fi

    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting" ]]; then
        git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git \
          "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting"
        print_success "fast-syntax-highlighting installed"
    else
        print_warning "fast-syntax-highlighting already installed, skipping..."
    fi
}

install_theme() {
    print_header "Set Up Theme"

    if prompt_user "Install and apply Gruvbox theme?" "n"; then
        bash "$DOTDIR/scripts/theme.sh"
    else
        print_warning "Skipping theme installation..."
    fi
}

configure_gnome() {
    print_header "GNOME Configuration"

    if prompt_user "Configure GNOME settings?" "n"; then
        bash "$DOTDIR/scripts/gnome.sh"
        print_success "GNOME configured"
    else
        print_warning "Skipping GNOME configuration..."
    fi
}

configure_git() {
    print_header "Git Configuration"

    if [[ ! -f "$HOME/.gitconfig" ]] && prompt_user "Configure git user settings?" "n"; then
        echo -n "Enter your git name: "
        read -r git_name
        echo -n "Enter your git email: "
        read -r git_email
        git config --global user.name "$git_name"
        git config --global user.email "$git_email"
        print_success "Git configured"
    else
        print_warning "Skipping git configuration..."
    fi
}

main() {
    print_header "Ubuntu Setup"

    check_ubuntu
    update_system
    install_packages
    setup_dotfiles
    install_omz
    install_tpm
    install_zsh_plugins
    install_theme
    configure_gnome
    configure_git

    if [[ $SHELL != /usr/bin/zsh ]]; then
        if ! grep -q "$(which zsh)" /etc/shells; then
            command -v zsh | sudo tee -a /etc/shells
        fi
        chsh -s "$(which zsh)"
        print_success "Default shell changed to zsh"
        print_warning "Please log out and log back in for the shell change to take effect."
    fi

    print_header "Setup Complete!"
    print_warning "You may need to restart your terminal or reboot to apply changes."
}

main "$@"
