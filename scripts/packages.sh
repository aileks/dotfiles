#!/usr/bin/env bash

set -e

source "$(dirname "$0")/common.sh"

install_essentials() {
    print_header "Installing Essential Tools"

    sudo apt update
    sudo apt install -y build-essential curl wget git unzip ubuntu-restricted-extras

    print_success "Essential build tools installed"
}

install_cli_tools() {
    print_header "Installing CLI Tools"

    local cli_packages=(
        "ripgrep"
        "eza"
        "fzf"
        "tmux"
        "jq"
        "tldr"
        "neovim"
        "trash-cli"
        "zsh"
    )

    sudo apt install -y "${cli_packages[@]}"
    print_success "CLI tools installed"
}

install_ghostty() {
    print_header "Installing Ghostty from .deb"

    local ghostty_deb_url="https://github.com/mkasberg/ghostty-ubuntu/releases/download/1.1.3-0-ppa2/ghostty_1.1.3-0.ppa2_amd64_24.04.deb"
    local deb_path="/tmp/ghostty.deb"

    curl -L "$ghostty_deb_url" -o "$deb_path"

    if [ $? -ne 0 ]; then
        print_error "Failed to download Ghostty .deb package."
        return 1
    fi

    sudo apt install -y "$deb_path"

    if [ $? -ne 0 ]; then
        print_error "Failed to install Ghostty."
        rm -f "$deb_path"
        return 1
    fi

    rm -f "$deb_path"
    print_success "Ghostty installed successfully"
}

install_github_cli() {
    print_header "Installing GitHub CLI"

    sudo mkdir -p -m 755 /etc/apt/keyrings
    out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg
    cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

    sudo apt update
    sudo apt install -y gh
    print_success "GitHub CLI installed"
}

install_font() {
    print_header "Installing Adwaita Mono Nerd Font"

    mkdir -p "$HOME/.local/share/fonts"
    wget -q "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/AdwaitaMono.zip" -O "/tmp/AdwaitaMono.zip"
    unzip -oq "/tmp/AdwaitaMono.zip" -d "$HOME/.local/share/fonts/"
    rm "/tmp/AdwaitaMono.zip"

    fc-cache -fv
    print_success "Adwaita Mono Nerd Font installed"
}

install_signal() {
    print_header "Installing Signal Desktop"

    if prompt_user "Do you want to install Signal Desktop?" "n"; then
        wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg;
        cat signal-desktop-keyring.gpg | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null

        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main" | sudo tee /etc/apt/sources.list.d/signal-xenial.list

        sudo apt update
        sudo apt install signal-desktop
        rm signal-desktop-keyring.gpg
        print_success "Signal Desktop installed"
    else
        print_warning "Skipping Signal Desktop installation..."
    fi
}

cleanup_system() {
    print_header "System Cleanup"
    sudo apt autoremove -y
    sudo apt clean
    print_success "System cleaned up"
}

main() {
    print_header "Installing General Packages"
    install_essentials
    install_cli_tools
    install_github_cli
    install_signal
    install_ghostty
    install_font
    install_flatpaks
    cleanup_system
    print_header "General Package Installation Complete!"
}

main "$@"
