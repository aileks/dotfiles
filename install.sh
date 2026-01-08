#!/bin/bash

set -euo pipefail

readonly LOG_RED='\033[0;31m'
readonly LOG_GREEN='\033[0;32m'
readonly LOG_YELLOW='\033[1;33m'
readonly LOG_BLUE='\033[0;34m'
readonly LOG_CYAN='\033[0;36m'
readonly LOG_NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config-backup.$(date +%Y%m%d_%H%M%S)"

DRY_RUN=false
DEBUG=false
SYMLINK_ONLY=false

# ============================================================
# Logging
# ============================================================

log_info() {
    echo -e "${LOG_BLUE}[INFO]${LOG_NC} $1"
}

log_success() {
    echo -e "${LOG_GREEN}[OK]${LOG_NC} $1"
}

log_warning() {
    echo -e "${LOG_YELLOW}[WARN]${LOG_NC} $1"
}

log_error() {
    echo -e "${LOG_RED}[ERROR]${LOG_NC} $1"
}

log_debug() {
    if [[ "$DEBUG" == true ]]; then
        echo -e "${LOG_CYAN}[DEBUG]${LOG_NC} $1"
    fi
}

log_dry() {
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${LOG_YELLOW}[DRY-RUN]${LOG_NC} Would: $1"
        return 0
    fi
    return 1
}

run_cmd() {
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${LOG_YELLOW}[DRY-RUN]${LOG_NC} $*"
        return 0
    fi
    log_debug "Running: $*"
    "$@"
}

command_exists() {
    command -v "$1" &>/dev/null
}

# ============================================================
# Package Lists
# ============================================================

PACMAN_PACKAGES=(
    # Core WM & X11
    xorg
    xorg-xinit
    xorg-xsetroot
    xorg-xrandr
    xorg-xset
    
    # DWM build deps
    libx11
    libxft
    libxinerama
    imlib2
    
    # Terminal & Shell
    zsh
    zsh-autosuggestions
    zsh-syntax-highlighting
    
    # Compositor & Notifications
    picom
    dunst
    libnotify
    
    # Launcher
    rofi
    
    # Screenshot & Clipboard
    maim
    xclip
    xdotool
    
    # System Controls
    pamixer
    playerctl
    networkmanager
    nm-connection-editor
    
    # CLI Tools
    fzf
    zoxide
    eza
    bat
    fd
    ripgrep
    trash-cli
    bc
    
    # File Managers
    yazi
    pcmanfm-gtk3
    
    # Applications
    zathura
    zathura-pdf-mupdf
    nsxiv
    feh
    fastfetch
    tmux
    btop
    calcurse
    
    # Fonts
    ttf-jetbrains-mono-nerd
    ttf-font-awesome
    noto-fonts
    noto-fonts-emoji
    
    # Icons
    papirus-icon-theme
)

AUR_PACKAGES=(
    wezterm-bin
    betterlockscreen
)

# ============================================================
# Package Installation
# ============================================================

install_pacman_packages() {
    log_info "Installing pacman packages..."
    
    local to_install=()
    
    for pkg in "${PACMAN_PACKAGES[@]}"; do
        if ! pacman -Qq "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done
    
    if [[ ${#to_install[@]} -eq 0 ]]; then
        log_success "All pacman packages already installed"
        return 0
    fi
    
    log_info "Installing ${#to_install[@]} packages: ${to_install[*]:0:5}..."
    
    if log_dry "sudo pacman -S --needed --noconfirm ${to_install[*]}"; then
        return 0
    fi
    
    if ! sudo pacman -S --needed --noconfirm "${to_install[@]}"; then
        log_error "Failed to install some pacman packages"
        return 1
    fi
    
    log_success "Pacman packages installed"
}

install_aur_packages() {
    log_info "Installing AUR packages..."
    
    local aur_helper=""
    if command_exists paru; then
        aur_helper="paru"
    elif command_exists yay; then
        aur_helper="yay"
    else
        log_error "No AUR helper found. Run setup.sh first."
        return 1
    fi
    
    local to_install=()
    
    for pkg in "${AUR_PACKAGES[@]}"; do
        if ! pacman -Qq "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done
    
    if [[ ${#to_install[@]} -eq 0 ]]; then
        log_success "All AUR packages already installed"
        return 0
    fi
    
    log_info "Installing ${#to_install[@]} AUR packages with $aur_helper"
    
    if log_dry "$aur_helper -S --needed --noconfirm ${to_install[*]}"; then
        return 0
    fi
    
    if ! $aur_helper -S --needed --noconfirm "${to_install[@]}"; then
        log_warning "Some AUR packages failed to install"
        return 1
    fi
    
    log_success "AUR packages installed"
}

# ============================================================
# Symlink Management
# ============================================================

backup_existing() {
    local target="$1"
    
    if [[ ! -e "$target" && ! -L "$target" ]]; then
        return 0
    fi
    
    if [[ -L "$target" ]]; then
        log_debug "Removing existing symlink: $target"
        if ! log_dry "rm $target"; then
            rm "$target"
        fi
        return 0
    fi
    
    mkdir -p "$BACKUP_DIR"
    local backup_path="$BACKUP_DIR/$(basename "$target")"
    
    log_warning "Backing up: $target -> $backup_path"
    
    if ! log_dry "mv $target $backup_path"; then
        mv "$target" "$backup_path"
    fi
}

create_symlink() {
    local source="$1"
    local target="$2"
    
    if [[ ! -e "$source" ]]; then
        log_warning "Source does not exist: $source"
        return 1
    fi
    
    backup_existing "$target"
    
    local target_dir
    target_dir=$(dirname "$target")
    
    if [[ ! -d "$target_dir" ]]; then
        if ! log_dry "mkdir -p $target_dir"; then
            mkdir -p "$target_dir"
        fi
    fi
    
    log_info "Linking: $target -> $source"
    
    if ! log_dry "ln -sf $source $target"; then
        ln -sf "$source" "$target"
    fi
}

symlink_configs() {
    log_info "Creating config symlinks..."
    
    mkdir -p ~/.config
    mkdir -p ~/.local/bin
    mkdir -p ~/.local/share/dwm
    
    # Direct directory symlinks
    create_symlink "$SCRIPT_DIR/wezterm" ~/.config/wezterm
    create_symlink "$SCRIPT_DIR/nvim" ~/.config/nvim
    create_symlink "$SCRIPT_DIR/picom" ~/.config/picom
    create_symlink "$SCRIPT_DIR/dunst" ~/.config/dunst
    create_symlink "$SCRIPT_DIR/zathura" ~/.config/zathura
    create_symlink "$SCRIPT_DIR/fastfetch" ~/.config/fastfetch
    create_symlink "$SCRIPT_DIR/rofi" ~/.config/rofi
    create_symlink "$SCRIPT_DIR/yazi" ~/.config/yazi
    
    # Single file symlinks
    create_symlink "$SCRIPT_DIR/betterlockscreen/betterlockscreenrc" ~/.config/betterlockscreen/betterlockscreenrc
    create_symlink "$SCRIPT_DIR/X11/xinitrc" ~/.xinitrc
    create_symlink "$SCRIPT_DIR/X11/Xresources" ~/.Xresources
    create_symlink "$SCRIPT_DIR/zsh/zshrc" ~/.zshrc
    create_symlink "$SCRIPT_DIR/tmux/tmux.conf" ~/.tmux.conf
    
    # Autostart script
    create_symlink "$SCRIPT_DIR/scripts/autostart.sh" ~/.local/share/dwm/autostart.sh
    
    # Status bar scripts
    if [[ -d "$SCRIPT_DIR/scripts/statusbar" ]]; then
        for script in "$SCRIPT_DIR/scripts/statusbar/"*; do
            [[ -f "$script" ]] || continue
            create_symlink "$script" ~/.local/bin/"$(basename "$script")"
            chmod +x "$script" 2>/dev/null || true
        done
    fi
    
    log_success "Config symlinks created"
}

# ============================================================
# Build Suckless Tools
# ============================================================

build_dwm() {
    log_info "Building DWM..."
    
    if [[ ! -d "$SCRIPT_DIR/dwm" ]]; then
        log_error "DWM directory not found: $SCRIPT_DIR/dwm"
        return 1
    fi
    
    if log_dry "cd $SCRIPT_DIR/dwm && sudo make clean install"; then
        return 0
    fi
    
    pushd "$SCRIPT_DIR/dwm" &>/dev/null
    
    if ! sudo make clean install; then
        log_error "Failed to build DWM"
        popd &>/dev/null
        return 1
    fi
    
    popd &>/dev/null
    log_success "DWM installed"
}

build_dwmblocks() {
    log_info "Building dwmblocks..."
    
    if [[ ! -d "$SCRIPT_DIR/dwmblocks" ]]; then
        log_error "dwmblocks directory not found: $SCRIPT_DIR/dwmblocks"
        return 1
    fi
    
    if log_dry "cd $SCRIPT_DIR/dwmblocks && sudo make clean install"; then
        return 0
    fi
    
    pushd "$SCRIPT_DIR/dwmblocks" &>/dev/null
    
    if ! sudo make clean install; then
        log_error "Failed to build dwmblocks"
        popd &>/dev/null
        return 1
    fi
    
    popd &>/dev/null
    log_success "dwmblocks installed"
}

# ============================================================
# Post-Install Tasks
# ============================================================

setup_shell() {
    log_info "Setting up shell..."
    
    if [[ "$SHELL" == *"zsh"* ]]; then
        log_success "Zsh already default shell"
        return 0
    fi
    
    if log_dry "chsh -s $(which zsh)"; then
        return 0
    fi
    
    if ! chsh -s "$(which zsh)"; then
        log_warning "Failed to change shell to zsh"
        log_info "Run manually: chsh -s \$(which zsh)"
    else
        log_success "Default shell set to zsh"
    fi
}

cache_lockscreen() {
    log_info "Caching lockscreen wallpaper..."
    
    local wallpaper="$SCRIPT_DIR/wallpaper.jpg"
    
    if [[ ! -f "$wallpaper" ]]; then
        log_warning "Wallpaper not found: $wallpaper"
        log_info "Add a wallpaper.jpg to your dotfiles and run: betterlockscreen -u wallpaper.jpg"
        return 0
    fi
    
    if ! command_exists betterlockscreen; then
        log_warning "betterlockscreen not installed, skipping"
        return 0
    fi
    
    if log_dry "betterlockscreen -u $wallpaper --blur 0.5"; then
        return 0
    fi
    
    if ! betterlockscreen -u "$wallpaper" --blur 0.5; then
        log_warning "Failed to cache lockscreen wallpaper"
    else
        log_success "Lockscreen wallpaper cached"
    fi
}

enable_services() {
    log_info "Enabling system services..."
    
    if log_dry "sudo systemctl enable NetworkManager"; then
        return 0
    fi
    
    if ! systemctl is-enabled NetworkManager &>/dev/null; then
        sudo systemctl enable --now NetworkManager
        log_success "NetworkManager enabled"
    else
        log_success "NetworkManager already enabled"
    fi
}

# ============================================================
# Interactive Menu
# ============================================================

show_menu() {
    echo
    echo -e "${LOG_BLUE}╔════════════════════════════════════════╗${LOG_NC}"
    echo -e "${LOG_BLUE}║${LOG_NC}    Arch Linux Dotfiles Installer       ${LOG_BLUE}║${LOG_NC}"
    echo -e "${LOG_BLUE}╚════════════════════════════════════════╝${LOG_NC}"
    echo
    echo "  1) Full setup (packages + symlinks + build)"
    echo "  2) Symlink configs only"
    echo "  3) Build suckless tools only (dwm + dwmblocks)"
    echo "  4) Install packages only"
    echo
    echo "  q) Quit"
    echo
    
    read -rp "Choose an option [1]: " choice
    choice=${choice:-1}
    
    case "$choice" in
        1) SYMLINK_ONLY=false ;;
        2) SYMLINK_ONLY=true ;;
        3)
            build_dwm
            build_dwmblocks
            exit 0
            ;;
        4)
            install_pacman_packages
            install_aur_packages
            exit 0
            ;;
        q|Q)
            log_info "Cancelled"
            exit 0
            ;;
        *)
            log_error "Invalid option: $choice"
            exit 1
            ;;
    esac
}

# ============================================================
# Argument Parsing
# ============================================================

show_help() {
    cat << EOF
Arch Linux Dotfiles Install Script

Usage:
  ./install.sh [OPTIONS] [MODE]

Options:
  -h, --help      Show this help message
  -d, --dry-run   Show what would be done without making changes
  --debug         Enable debug output

Modes:
  1               Full setup (default)
  2               Symlink configs only

Examples:
  ./install.sh              # Interactive menu
  ./install.sh 1            # Full setup
  ./install.sh 2            # Symlink only
  ./install.sh --dry-run 1  # Preview full setup
EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                log_warning "Dry-run mode enabled"
                ;;
            --debug)
                DEBUG=true
                log_debug "Debug mode enabled"
                ;;
            1)
                SYMLINK_ONLY=false
                ;;
            2)
                SYMLINK_ONLY=true
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done
}

# ============================================================
# Main
# ============================================================

main() {
    parse_arguments "$@"
    
    # Show menu if no mode specified via args
    if [[ $# -eq 0 ]] || { [[ "$DRY_RUN" == true || "$DEBUG" == true ]] && [[ $# -le 2 ]]; }; then
        local has_mode=false
        for arg in "$@"; do
            [[ "$arg" == "1" || "$arg" == "2" ]] && has_mode=true
        done
        [[ "$has_mode" == false ]] && show_menu
    fi
    
    echo
    log_info "Starting installation..."
    log_info "Dotfiles directory: $SCRIPT_DIR"
    echo
    
    if [[ "$SYMLINK_ONLY" == true ]]; then
        symlink_configs
    else
        install_pacman_packages
        install_aur_packages
        symlink_configs
        build_dwm
        build_dwmblocks
        setup_shell
        enable_services
        cache_lockscreen
    fi
    
    echo
    log_success "═══════════════════════════════════════"
    log_success "  Installation complete!"
    log_success "═══════════════════════════════════════"
    echo
    
    if [[ -d "$BACKUP_DIR" ]]; then
        log_info "Backups saved to: $BACKUP_DIR"
    fi
    
    if [[ "$DRY_RUN" == false ]]; then
        echo
        log_info "Next steps:"
        echo "  1. Log out and log back in (or reboot)"
        echo "  2. Start X with: startx"
        echo
    fi
}

main "$@"
