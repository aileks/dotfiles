#!/usr/bin/env bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
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

install_codecs() {
    print_header "Installing Multimedia Codecs"

    echo "Installing multimedia meta package..."
    sudo dnf group install -y multimedia
    sudo dnf swap ffmpeg-free ffmpeg --allowerasing -y
    print_success "Multimedia codecs installed"
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
        "zsh"
    )

    echo "Installing CLI tools..."
    for package in "${cli_packages[@]}"; do
        echo "Installing $package..."
        sudo dnf install -y "$package" || print_warning "Failed to install $package"
    done

    chsh -s $(which zsh)

    print_success "CLI tools installed"
}

install_github_cli() {
    print_header "Installing GitHub CLI"

    echo "Setting up GitHub CLI repository..."
    sudo dnf install -y dnf5-plugins
    sudo dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo --overwrite

    echo "Installing GitHub CLI..."
    sudo dnf install -y gh --repo gh-cli

    print_success "GitHub CLI installed"
}

install_dev_tools() {
    print_header "Installing Development Tools"

    echo "Installing Podman and Podman Compose..."
    sudo dnf install -y podman podman-compose
    print_success "Podman and Podman Compose installed"

    echo "Cloning LazyVim starter..."
    git clone https://github.com/LazyVim/starter ~/.config/nvim && rm -rf ~/.config/nvim/.git
    print_success "LazyVim starter installed"

    echo "Installing Zed Preview..."
    curl -f https://zed.dev/install.sh | ZED_CHANNEL=preview sh
    print_success "Zed Preview installed"

    echo "Setting up NVIDIA CUDA repository..."
    sudo dnf config-manager addrepo --from-repofile https://developer.download.nvidia.com/compute/cuda/repos/fedora41/x86_64/cuda-fedora41.repo --overwrite
    sudo dnf clean all

    echo "Installing NVIDIA CUDA Toolkit 12.9..."
    sudo dnf -y install cuda-toolkit-12-9 nvidia-container-toolkit
    print_success "NVIDIA CUDA Toolkit installed"

    print_success "All development tools installed"
}

install_font() {
    print_header "Installing Adwaita Mono Nerd Font"

    mkdir -p "$HOME/.local/share/fonts"

    echo "Downloading Adwaita Mono Nerd Font..."
    wget -q "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/AdwaitaMono.zip" -O "/tmp/AdwaitaMono.zip"

    echo "Installing font..."
    unzip -q "/tmp/AdwaitaMono.zip" -d "$HOME/.local/share/fonts/"
    rm "/tmp/AdwaitaMono.zip"

    fc-cache -fv
    print_success "Adwaita Mono Nerd Font installed"
}

install_flatpaks() {
    print_header "Installing Flatpak Applications"

    echo "Adding Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    echo "Installing Zoom..."
    flatpak install -y flathub us.zoom.Zoom || print_warning "Failed to install Zoom"

    echo "Installing Signal Desktop..."
    flatpak install -y flathub org.signal.Signal || print_warning "Failed to install Signal Desktop"

    print_success "Flatpak applications installed"
}

install_conda() {
    print_header "Installing Miniconda"

    echo "Downloading Miniconda installer..."
    wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh

    echo "Installing Miniconda..."
    bash /tmp/miniconda.sh -b -p "$HOME/.miniconda3"

    echo "Initializing conda..."
    "$HOME/.miniconda3/bin/conda" init zsh

    rm /tmp/miniconda.sh

    print_success "Conda installed and initialized"
    print_warning "You may need to restart your terminal for conda to be available"
}

install_mise() {
    print_header "Installing mise (Runtime Version Manager)"

    echo "Installing mise..."
    curl https://mise.run | sh

    echo 'eval "$(~/.local/bin/mise activate zsh)"' >> "$HOME/.zshrc" || true

    print_success "mise installed"
    print_warning "mise has been added to your shell configuration"
}

cleanup_system() {
    print_header "System Cleanup"

    echo "Cleaning up package cache..."
    sudo dnf autoremove -y
    sudo dnf clean all
    print_success "System cleaned up"
}

main() {
    print_header "Installing Custom Package Set"
    print_warning "This will install your specific development tools and applications."

    install_codecs
    install_cli_tools
    install_github_cli
    install_dev_tools
    install_font
    install_flatpaks
    install_conda
    install_mise
    cleanup_system

    print_header "Package Installation Complete!"
    print_success "All your custom packages have been installed."
    print_warning "Note: You may need to restart your terminal for some tools (conda, mise) to be fully available."
}

main "$@"
