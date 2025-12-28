#!/bin/zsh

set -euo pipefail

readonly SCRIPT_NAME="${(%):-%N}"
readonly SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$SCRIPT_NAME" || echo "$SCRIPT_NAME")")" && pwd -P)"
readonly DOTFILES_REPO="https://github.com/aileks/dotfiles.git"
readonly DOTFILES_DIR="$HOME/.dotfiles"
readonly BACKUP_SUFFIX=".backup.$(date +%Y%m%d_%H%M%S)"

source "$SCRIPT_DIR/lib/logging.zsh"

cleanup_on_error() {
    log_error "Script failed. Check the output above for details."
    exit 1
}

trap cleanup_on_error ERR

TOTAL_STEPS=8
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

cleanup_and_finish() {
    show_progress "Cleaning up and finishing"

    if command_exists brew; then
        log_info "Running Homebrew cleanup..."
        dry_run_or_execute "brew cleanup &>/dev/null"
    fi

    log_success "macOS setup completed successfully!"
    echo
    echo "Next steps:"
    echo "  1. Run 'brew doctor' to check for any issues"
    echo "  2. Restart your Mac"
    echo "  3. Configure any installed applications as needed"

    local backup_zshrc
    backup_zshrc=$(find "$HOME" -maxdepth 1 -name ".zshrc.backup.*" -print -quit 2>/dev/null || true)
    if [[ -n "$backup_zshrc" ]]; then
        echo "  4. Your old .zshrc was backed up to: $backup_zshrc"
    fi
}

run_full_setup() {
    source "$SCRIPT_DIR/lib/packages.zsh"
    source "$SCRIPT_DIR/lib/dotfiles.zsh"
    source "$SCRIPT_DIR/lib/ohmyzsh.zsh"
    
    log_info "Starting full macOS setup..."
    
    check_system
    check_prerequisites || exit 1
    
    install_xcode_tools || exit 1
    install_homebrew || exit 1
    setup_dotfiles || exit 1
    install_packages || exit 1
    install_oh_my_zsh || exit 1
    install_node || exit 1
    
    cleanup_and_finish
}

run_dotfiles_update() {
    source "$SCRIPT_DIR/lib/validation.zsh"
    source "$SCRIPT_DIR/lib/dotfiles.zsh"
    
    log_info "Starting dotfiles update..."
    
    TOTAL_STEPS=2
    CURRENT_STEP=0
    
    check_prerequisites || exit 1
    
    update_dotfiles || exit 1
}

show_help() {
    local script_name
    script_name=$(basename "$SCRIPT_NAME")
    cat << EOF
Usage: $script_name [OPTIONS]

Options:
    -h, --help          Show this help message
    -d, --dry-run       Run in dry-run mode (no changes made)
    --debug             Enable debug output
    1                   Full macOS setup
    2                   Update and symlink dotfiles only

If no option is provided, an interactive menu will be displayed.
EOF
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                set_dry_run
                shift
                ;;
            --debug)
                set_debug_mode
                shift
                ;;
            1)
                run_full_setup
                exit 0
                ;;
            2)
                run_dotfiles_update
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo
                show_help
                exit 1
                ;;
        esac
    done

    echo -e "${LOG_YELLOW}Which would you like to do?${LOG_NC}"
    echo "  1) Perform a full macOS setup (sudo password required for some steps)"
    echo "  2) Update and symlink dotfiles only"
    echo "  h) Show help"
    echo "  q) Quit"
    
    while true; do
        read -r "choice?Enter your choice (1, 2, h, or q): "
        
        case "$choice" in
            1)
                echo
                run_full_setup
                break
                ;;
            2)
                echo
                run_dotfiles_update
                break
                ;;
            h|H)
                echo
                show_help
                ;;
            q|Q)
                echo "Exiting..."
                exit 0
                ;;
            *)
                log_error "Invalid choice: $choice"
                ;;
        esac
    done
}

main "$@"
