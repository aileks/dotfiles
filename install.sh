#!/usr/bin/env bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

prompt_user() {
    local question="$1"
    local default="${2:-n}"
    local prompt

    if [[ "$default" == "y" ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi

    while true; do
        echo -e "${YELLOW}$question $prompt${NC}"
        read -r response

        # Use default if response is empty
        if [[ -z "$response" ]]; then
            response="$default"
        fi

        case "$response" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
            *) echo -e "${RED}Please answer yes or no.${NC}" ;;
        esac
    done
}

check_fedora() {
    if [[ ! -f /etc/fedora-release ]]; then
        print_error "This script is designed for Fedora Linux."
        exit 1
    fi
    print_success "Fedora detected"
}

update_system() {
    print_header "Updating System"

    if prompt_user "Update system packages?" "y"; then
        sudo dnf update -y
        print_success "System updated"
    else
        print_warning "Skipping system update..."
    fi
}

install_packages() {
    print_header "Package Installation"

    if prompt_user "Would you like to install the full package set?" "n"; then
        if [[ -f "$DOTDIR/scripts/packages.sh" ]]; then
            bash "$DOTDIR/scripts/packages.sh"

            if prompt_user "Log in with GitHub CLI?" "y"; then
                gh auth login
            fi
        else
            print_error "Package script not found at $DOTDIR/scripts/packages.sh"
        fi
    else
        print_warning "Skipping all package installation..."
    fi
}

setup_dotfiles() {
    print_header "Setting Up Dotfiles"

    echo "Creating symlinks for dotfiles..."

    for file in ".tmux.conf" ".zshrc"; do
        if [[ -f "$HOME/$file" && ! -L "$HOME/$file" ]]; then
            print_warning "Backing up existing $file to ${file}.bak"
            mv "$HOME/$file" "$HOME/${file}.bak"
        fi
    done

    if [[ -f "$DOTDIR/tmux/tmux.conf" ]]; then
        ln -sf "$DOTDIR/tmux/tmux.conf" "$HOME/.tmux.conf"
        print_success "Linked tmux.conf"
    fi

    if [[ -f "$DOTDIR/zsh/zshrc" ]]; then
        ln -sf "$DOTDIR/zsh/zshrc" "$HOME/.zshrc"
        print_success "Linked zshrc"
    fi

    CONFIG_DIRS=("ghostty" "zed" "fastfetch")
    echo -e "\nCreating symlinks for .config directories..."

    mkdir -p "$HOME/.config"

    for dir in "${CONFIG_DIRS[@]}"; do
        if [[ -d "$DOTDIR/$dir" ]]; then
            echo "Setting up $dir"
            # Backup existing directory
            if [[ -d "$HOME/.config/$dir" && ! -L "$HOME/.config/$dir" ]]; then
                print_warning "Backing up existing .config/$dir to .config/${dir}.bak"
                mv "$HOME/.config/$dir" "$HOME/.config/${dir}.bak"
            fi
            rm -rf "$HOME/.config/$dir"
            ln -s "$DOTDIR/$dir" "$HOME/.config/$dir"
            print_success "Linked $dir config"
        else
            print_warning "$dir directory not found, skipping..."
        fi
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

configure_git() {
    print_header "Git Configuration"

    if prompt_user "Configure git user settings?" "n"; then
        echo -n "Enter your git name: "
        read -r git_username
        echo -n "Enter your git email: "
        read -r git_email

        git config --global user.name "$git_username"
        git config --global user.email "$git_email"
        print_success "Git configured"
    else
        print_warning "Skipping git configuration..."
    fi
}

main() {
    print_header "Fedora Setup"

    check_fedora
    update_system
    install_packages
    setup_dotfiles
    install_omz
    install_tpm
    install_zsh_plugins
    configure_git

    chsh -s "$(which zsh)"
    print_success "Default shell changed to zsh"
    print_warning "Please log out and log back in for the shell change to take effect."

    print_header "Setup Complete!"
    print_warning "You may need to restart your terminal or run \`source ~/.zshrc\` to apply changes."

}

main "$@"
