#!/usr/bin/env bash

set -e

source "$(dirname "$0")/common.sh"

install_tools() {
    if [ ! -d "$HOME/.config/nvim" ]; then
      git clone https://github.com/LazyVim/starter ~/.config/nvim && rm -rf ~/.config/nvim/.git
      print_success "LazyVim starter installed"
    else
      print_warning "Neovim config already exists, skipping LazyVim starter."
    fi

    curl -f https://zed.dev/install.sh | ZED_CHANNEL=preview sh
    print_success "Zed Preview installed"

    if prompt_user "Install CUDA Toolkit?" "n"; then
      wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
      sudo dpkg -i cuda-keyring_1.1-1_all.deb
      rm cuda-keyring_1.1-1_all.deb

      sudo apt update
      sudo apt -y install cuda-toolkit-12-8
      print_success "CUDA Toolkit installed"
    else
        echo "Skipping CUDA Toolkit installation..."
    fi
}

install_conda() {
    print_header "Installing Miniconda"

    wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh
    bash /tmp/miniconda.sh -b -p "$HOME/.miniconda3"
    "$HOME/.miniconda3/bin/conda" init zsh
    rm /tmp/miniconda.sh

    print_success "Conda installed and initialized"
}

install_mise() {
    print_header "Installing mise"

    curl https://mise.run | sh
    print_success "mise installed"
}


install_github_cli() {
    print_header "Install GitHub CLI"

    sudo mkdir -p -m 755 /etc/apt/keyrings
    out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg
    cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

    sudo apt update
    sudo apt install -y gh
    print_success "GitHub CLI installed"
}

main() {
    print_header "Installing Development Tools"

    install_tools
    install_conda
    install_mise
    install_github_cli

    print_header "Development Tools Installation Complete!"
    print_warning "You may need to restart your terminal for some changes to take effect."
}

main "$@"
