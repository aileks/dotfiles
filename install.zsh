#!/bin/zsh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

DOTFILES_REPO="https://github.com/aileks/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_SUFFIX=".backup.$(date +%Y%m%d_%H%M%S)"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

cleanup_on_error() {
    log_error "Script failed. Check the output above for details."
    exit 1
}

trap cleanup_on_error ERR

command_exists() {
    command -v "$1" &>/dev/null
}

wait_for_user() {
    local message="$1"
    echo -e "${YELLOW}$message${NC}"
    read -p "Press Enter to continue..."
}

TOTAL_STEPS=9
CURRENT_STEP=0

show_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    log_step "[$CURRENT_STEP/$TOTAL_STEPS] $1"
}

check_system() {
    show_progress "Checking system requirements"

    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS only."
        exit 1
    fi

    log_info "Running on macOS $(sw_vers -productVersion)"

    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        exit 1
    fi
}

create_symlink() {
    local src="$1"
    local dest="$2"
    local dest_dir

    dest_dir=$(dirname "$dest")
    if [[ ! -d "$dest_dir" ]]; then
        mkdir -p "$dest_dir"
        log_info "Created directory: $dest_dir"
    fi

    if [[ -e "$dest" && ! -L "$dest" ]] || [[ -L "$dest" && ! -e "$dest" ]]; then
        log_info "Backing up existing file/directory: $dest"
        mv "$dest" "${dest}${BACKUP_SUFFIX}"
    elif [[ -L "$dest" ]]; then
        log_info "Removing existing symlink: $dest"
        rm "$dest"
    fi

    if ln -s "$src" "$dest"; then
        log_success "Created symlink: $dest -> $src"
    else
        log_error "Failed to create symlink: $dest -> $src"
        return 1
    fi
}

install_xcode_tools() {
    show_progress "Installing Xcode Command Line Tools"

    if ! xcode-select -p &>/dev/null; then
        log_warning "Xcode Command Line Tools not found!"
        log_info "Installing Xcode Command Line Tools..."
        xcode-select --install || true

        log_info "Waiting for Xcode Command Line Tools installation to complete..."

        until xcode-select -p &>/dev/null; do
            echo -e "${YELLOW}Xcode Command Line Tools are still installing... ${NC}"
            sleep 20
        done
    fi

    log_success "Xcode Command Line Tools are installed"
}

install_homebrew() {
    show_progress "Setting up Homebrew"

    if ! command_exists brew; then
        log_info "Installing Homebrew..."
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        if [[ $(uname -m) == "arm64" ]]; then
            if ! grep -q "/opt/homebrew/bin/brew" "$HOME/.zprofile" 2>/dev/null; then
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$HOME/.zprofile"
            fi
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi

        log_success "Homebrew installed successfully"
    else
        log_info "Homebrew already installed, updating..."
        brew update
        log_success "Homebrew updated"
    fi
}

install_packages() {
    show_progress "Installing packages from Brewfile"

    local brewfile_path="$DOTFILES_DIR/Brewfile"

    if [[ ! -f "$brewfile_path" ]]; then
        log_error "Brewfile not found at $brewfile_path"
        return 1
    fi

    log_info "Installing packages and applications from Brewfile..."
    if brew bundle install --file="$brewfile_path"; then
        log_success "All packages from Brewfile installed successfully"
    else
        log_warning "Some packages may have failed to install from Brewfile"
        log_info "You can check which packages failed and install them manually"
    fi
}

install_oh_my_zsh() {
    show_progress "Setting up Oh-My-Zsh"

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Installing Oh-My-Zsh..."
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        log_success "Oh-My-Zsh installed successfully"
    else
        log_info "Oh-My-Zsh already installed"
    fi

    if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions \
            ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    fi

    if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/fast-syntax-highlighting" ]]; then
        git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git \
            "$HOME/.oh-my-zsh/custom/plugins/fast-syntax-highlighting"
    fi
}

setup_dotfiles() {
    if [[ "$TOTAL_STEPS" -gt 1 ]]; then
        show_progress "Setting up dotfiles"
    fi

    if [[ -d "$DOTFILES_DIR" ]]; then
        log_info "Dotfiles directory already exists, updating..."
        cd "$DOTFILES_DIR"
        if git pull origin main &>/dev/null; then
            log_success "Dotfiles updated successfully"
        else
            log_warning "Failed to update dotfiles, continuing with existing version"
        fi
        cd - &>/dev/null
    else
        log_info "Cloning dotfiles repository..."
        if git clone "$DOTFILES_REPO" "$DOTFILES_DIR" &>/dev/null; then
            log_success "Dotfiles cloned successfully"
        else
            log_error "Failed to clone dotfiles repository"
            return 1
        fi
    fi

    log_info "Initializing git submodules..."
    cd "$DOTFILES_DIR"
    if git submodule update --init --recursive &>/dev/null; then
        log_success "Git submodules initialized successfully"
    else
        log_warning "Failed to initialize git submodules, continuing anyway"
    fi
    cd - &>/dev/null

    log_info "Creating symlinks for dotfiles..."
    local symlink_mappings=(
        "zsh/zshrc:$HOME/.zshrc"
        "nvim:$HOME/.config/nvim"
        "fastfetch:$HOME/.config/fastfetch"
        "ghostty:$HOME/.config/ghostty"
        "aerospace:$HOME/.config/aerospace"
        "borders:$HOME/.config/borders"
        "tmux/tmux.conf:$HOME/.tmux.conf"
    )

    for mapping in "${symlink_mappings[@]}"; do
        local src_path="${mapping%%:*}"
        local dest_path="${mapping##*:}"
        local full_src_path="$DOTFILES_DIR/$src_path"

        if [[ -e "$full_src_path" ]]; then
            create_symlink "$full_src_path" "$dest_path"
        else
            log_warning "Source file/directory not found: $full_src_path - skipping symlink creation"
        fi
    done

    if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    fi
}

install_node() {
    show_progress "Setting up Node.js"

    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    mkdir -p "$NVM_DIR"

    if ! command -v nvm &>/dev/null; then
        if command_exists brew; then
            if ! brew list --formula nvm &>/dev/null; then
                log_info "Installing nvm via Homebrew..."
                brew install nvm
            fi
            if [[ -s "$(brew --prefix nvm)/nvm.sh" ]]; then
                source "$(brew --prefix nvm)/nvm.sh"
            fi
        fi

        # Fallback to standard location if present
        if [[ -z "${functions[nvm]-}" && -s "$NVM_DIR/nvm.sh" ]]; then
            source "$NVM_DIR/nvm.sh"
        fi
    fi

    if command -v nvm &>/dev/null; then
        log_info "Installing Node.js LTS..."
        nvm install --lts
        nvm use --lts
        log_success "Node.js LTS installed and set as default"

        log_info "Installing pnpm..."
        npm install --global corepack@latest
        corepack enable pnpm
        corepack use pnpm@latest-10
        log_success "pnpm installed successfully!"
    else
        log_warning "nvm is not available in this shell; skipping Node installation. Ensure your shell loads nvm and run: nvm install --lts"
    fi
}

update_dotfiles() {
    TOTAL_STEPS=1

    CURRENT_STEP=0

    show_progress "Updating and re-linking dotfiles"

    if ! command_exists git; then
        log_error "Git is not installed. Please install Git and try again, or run the full setup."
        exit 1
    fi
    log_info "Prerequisite check passed: Git is installed."

    setup_dotfiles

    echo
    log_success "Dotfiles have been updated and re-linked successfully."
    log_info "Restart your terminal or run 'source ~/.zshrc' to apply changes."
}

cleanup_and_finish() {
    show_progress "Cleaning up and finishing"

    log_info "Running Homebrew cleanup..."
    brew cleanup &>/dev/null

    log_success "macOS setup completed successfully!"
    echo
    echo "Next steps:"
    echo "  1. Run 'brew doctor' to check for any issues"
    echo "  2. Restart your Mac"
    echo "  3. Configure any installed applications as needed"

    local backup_zshrc
    backup_zshrc=$(find "$HOME" -maxdepth 1 -name ".zshrc.backup.*" -print -quit)
    if [[ -n "$backup_zshrc" ]]; then
        echo "  4. Your old .zshrc was backed up to: $backup_zshrc"
    fi
}

main() {
    echo -e "${YELLOW}Which would you like to do?${NC}"
    echo "  1) Perform a full macOS setup (sudo password required for some steps)"
    echo "  2) Update and symlink dotfiles only"
    read -r "choice?Enter your choice (1 or 2): "
    echo

    case "$choice" in
    1)
        log_info "Starting full macOS setup..."
        check_system
        install_xcode_tools
        install_homebrew
        setup_dotfiles
        install_packages
        install_oh_my_zsh
        install_node
        cleanup_and_finish
        ;;
    2)
        log_info "Starting dotfiles update..."
        update_dotfiles
        ;;
    *)
        log_error "Invalid choice. Please run the script again and enter 1 or 2."
        exit 1
        ;;
    esac
}

main "$@"
