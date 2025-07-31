#!/usr/bin/env bash

set -e

source "$(dirname "$0")/common.sh"

install_essentials() {
    print_header "Install Essentials"

    local essentials=( "build-essential" "gnome-tweaks" "gnome-shell-extension-manager" "ubuntu-restricted-extras" )

    sudo apt update
    sudo apt install -y "${essentials[@]}"

    print_success "Essential tools installed"
}

install_cli_tools() {
    print_header "Install CLI Utils"

    local cli_packages=( "git" "axel" "unzip" "ripgrep" "wl-clipboard" "zoxide" "eza" "fzf"
        "tmux" "jq" "tldr" "btop" "trash-cli" "zoxide" "zsh" )

    sudo apt install -y "${cli_packages[@]}"
    print_success "CLI utils installed"
}

install_pacstall_packages() {
    print_header "Pacstall Setup"

    local pacstall_packages=( "neovim" "fastfetch" )

    print_info "Installing Pacstall..."
    sudo bash -c "$(curl -fsSL https://pacstall.dev/q/install)"

    print_info "Installing packages..."
    sudo pacstall -S "${pacstall_packages[@]}"

    print_success "Pacstall setup and packages installed"
}

install_ghostty() {
    print_header "Install Ghostty"

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
    sudo update-alternatives --set x-terminal-emulator /usr/bin/ghostty
    print_success "Ghostty installed successfully"
}


install_font() {
    print_header "Install Adwaita Fonts"

    mkdir -p "$HOME/.local/share/fonts"

    git clone https://gitlab.gnome.org/GNOME/adwaita-fonts.git /tmp/adwaita-fonts
    cp /tmp/adwaita-fonts/sans/*.ttf "$HOME/.local/share/fonts/"
    rm -rf "/tmp/adwaita-fonts"

    wget -q "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/AdwaitaMono.zip" -O "/tmp/AdwaitaMono.zip"
    unzip -oq "/tmp/AdwaitaMono.zip" -d "$HOME/.local/share/fonts/"
    rm "/tmp/AdwaitaMono.zip"

    fc-cache -fv
    print_success "Adwaita Fonts installed"
}

install_signal() {
    print_header "Install Signal Desktop"

    if prompt_user "Do you want to install Signal Desktop?" "y"; then
        wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg;
        cat signal-desktop-keyring.gpg | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null

        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main" | sudo tee /etc/apt/sources.list.d/signal-xenial.list

        sudo apt update
        sudo apt install -y signal-desktop
        rm signal-desktop-keyring.gpg
        print_success "Signal Desktop installed"
    else
        print_warning "Skipping Signal Desktop installation..."
    fi
}

install_albert() {
    print_header "Install Albert"

    if prompt_user "Do you want to install Albert?" "y"; then
        echo "deb http://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_24.04/ /" | sudo tee /etc/apt/sources.list.d/home:manuelschneid3r.list
        curl -fsSL https://download.opensuse.org/repositories/home:manuelschneid3r/xUbuntu_24.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_manuelschneid3r.gpg > /dev/null

        sudo apt update
        sudo apt install -y albert
        print_success "Albert installed"
    else
        print_warning "Skipping Albert installation..."
    fi
}

remove_snaps() {
    print_header "Remove Snaps"

    if prompt_user "Completely remove snapd and all snap packages?" "y"; then
        local snaps_to_remove=(
            "firefox"
            "snap-store"
            "gtk-common-themes"
            "gnome-42-2204"
            "snapd-desktop-integration"
            "firmware-updater"
            "core22"
            "bare"
            "snapd"
        )

        for snap in "${snaps_to_remove[@]}"; do
            sudo snap remove --purge -y "$snap"
        done

        sudo apt autoremove --purge -y snapd
        sudo rm -rf ~/snap
        sudo rm -rf /snap

        print_info "Blacklisting snaps..."
        cat <<EOF | sudo tee /etc/apt/preferences.d/no-snapd.pref
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF

        sudo apt update
        sudo apt install --install-suggests -y gnome-software
        print_success "Snaps have been completely removed and blocked."
    else
        print_warning "Skipping snap removal..."
    fi
}

cleanup_system() {
    print_header "System Cleanup"
    sudo apt autoremove -y
    print_success "Cleanup complete"
}

main() {
    install_essentials
    install_cli_tools
    install_ghostty
    install_font
    install_signal
    install_albert
    install_pacstall_packages
    remove_snaps

    if prompt_user "Install Brave Browser?" "y"; then
        curl -fsS https://dl.brave.com/install.sh | sh
    else
        print_warning "Skipping Brave Browser install..."
    fi

    cleanup_system

    print_success "Package installation complete"
}

main "$@"
