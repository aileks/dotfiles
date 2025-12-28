#!/bin/zsh

set -euo pipefail

readonly LOG_RED='\033[0;31m'
readonly LOG_GREEN='\033[0;32m'
readonly LOG_YELLOW='\033[1;33m'
readonly LOG_BLUE='\033[0;34m'
readonly LOG_NC='\033[0m'

DOTFILES_REPO="https://github.com/aileks/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_SUFFIX=".backup.$(date +%Y%m%d_%H%M%S)"
PASS_THROUGH_ARGS=()

show_help() {
    cat << EOF
macOS Dotfiles Bootstrap Installer

This installer will:
  1. Install Xcode Command Line Tools if needed
  2. Clone/update your dotfiles to ~/.dotfiles
  3. Initialize git submodules
  4. Run the full setup script

Usage:
  curl -fsSL https://aileks.dev/mac | zsh [OPTIONS]

Options:
  -h, --help          Show this help message
  -d, --dry-run       Pass dry-run mode to setup script
  --debug             Enable debug output in setup script
  1                   Perform full macOS setup (default)
  2                   Update and symlink dotfiles only

If no option is provided, an interactive menu will be displayed.
EOF
}

log_info() {
    echo -e "${LOG_BLUE}[BOOTSTRAP]${LOG_NC} $1"
}

log_success() {
    echo -e "${LOG_GREEN}[BOOTSTRAP]${LOG_NC} $1"
}

log_warning() {
    echo -e "${LOG_YELLOW}[BOOTSTRAP]${LOG_NC} $1"
}

log_error() {
    echo -e "${LOG_RED}[BOOTSTRAP]${LOG_NC} $1"
}

command_exists() {
    command -v "$1" &>/dev/null
    return $?
}

install_xcode_tools() {
    log_info "Installing Xcode Command Line Tools..."

    if xcode-select -p &>/dev/null; then
        log_success "Xcode Command Line Tools already installed"
        return 0
    fi

    if ! xcode-select --install 2>/dev/null; then
        log_warning "Installation may already be in progress"
    fi

    local elapsed=0
    local wait_interval=30
    local timeout=1800

    while ! xcode-select -p &>/dev/null; do
        if [[ $elapsed -ge $timeout ]]; then
            log_error "Xcode Command Line Tools installation timed out after ${timeout}s"
            log_error "Please install manually: xcode-select --install"
            exit 1
        fi
        log_info "Waiting for installation... (${elapsed}/${timeout}s)"
        sleep $wait_interval
        elapsed=$((elapsed + wait_interval))
    done

    log_success "Xcode Command Line Tools installed"
}

verify_dotfiles_repo() {
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        return 1
    fi

    if ! command_exists git; then
        return 1
    fi

    pushd "$DOTFILES_DIR" &>/dev/null || return 1

    if ! git rev-parse --git-dir &>/dev/null; then
        popd &>/dev/null || true
        return 1
    fi

    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null || echo "")

    popd &>/dev/null || true

    if [[ "$remote_url" == *"$DOTFILES_REPO"* ]] || [[ "$remote_url" == *"aileks/dotfiles"* ]]; then
        return 0
    fi

    return 1
}

prompt_replace_repo() {
    local existing_url
    existing_url=$(cd "$DOTFILES_DIR" 2>/dev/null && git remote get-url origin 2>/dev/null || echo "unknown")

    echo
    log_warning "Existing repository found at ~/.dotfiles"
    echo "  Expected: $DOTFILES_REPO"
    echo "  Found: $existing_url"
    echo
    echo "Choose an option:"
    echo "  1) Backup and replace existing repository"
    echo "  2) Cancel installation"
    echo

    while true; do
        read -r "choice?Enter your choice (1 or 2): "
        case "$choice" in
            1)
                log_info "Backing up existing repository..."
                mv "$DOTFILES_DIR" "${DOTFILES_DIR}${BACKUP_SUFFIX}"
                log_success "Backed up to: ${DOTFILES_DIR}${BACKUP_SUFFIX}"
                return 0
                ;;
            2)
                log_info "Installation cancelled"
                exit 0
                ;;
            *)
                log_error "Invalid choice: $choice"
                ;;
        esac
    done
}

update_existing_repo() {
    log_info "Updating existing dotfiles repository..."

    if ! cd "$DOTFILES_DIR"; then
        log_error "Failed to enter dotfiles directory"
        return 1
    fi

    if ! git fetch origin &>/dev/null; then
        log_warning "Failed to fetch updates, continuing with local version"
        cd - &>/dev/null || true
        return 0
    fi

    local local_ref
    local_ref=$(git rev-parse HEAD 2>/dev/null || echo "")

    local default_branch
    default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

    local remote_ref
    remote_ref=$(git rev-parse "origin/$default_branch" 2>/dev/null || echo "")

    if [[ "$local_ref" == "$remote_ref" ]]; then
        log_success "Already up to date"
    else
        git reset --hard "origin/$default_branch" &>/dev/null
        log_success "Repository updated to latest version"
    fi

    cd - &>/dev/null || true
    return 0
}

clone_repo() {
    log_info "Cloning dotfiles repository..."

    local retries=3
    local delay=5
    local i=1

    while [[ $i -le $retries ]]; do
        if git clone "$DOTFILES_REPO" "$DOTFILES_DIR"; then
            log_success "Repository cloned successfully"
            return 0
        fi
        log_warning "Clone failed (attempt $i/$retries)"
        if [[ $i -lt $retries ]]; then
            sleep $delay
        fi
        i=$((i + 1))
    done

    log_error "Failed to clone repository after $retries attempts"
    return 1
}

init_submodules() {
    log_info "Initializing git submodules..."

    if ! cd "$DOTFILES_DIR"; then
        log_error "Failed to enter dotfiles directory"
        return 1
    fi

    if ! git submodule update --init --recursive; then
        log_warning "Failed to initialize some submodules, continuing anyway"
    else
        log_success "Submodules initialized"
    fi

    cd - &>/dev/null || true
    return 0
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                PASS_THROUGH_ARGS+=("$1")
                ;;
        esac
        shift
    done
}

main() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS only."
        exit 1
    fi

    parse_arguments "$@"

    log_info "Starting bootstrap installer..."

    if ! command_exists git; then
        install_xcode_tools || exit 1

        if ! command_exists git; then
            log_error "Git still not available after Xcode installation"
            exit 1
        fi
    fi

    if verify_dotfiles_repo; then
        update_existing_repo || exit 1
    elif [[ -d "$DOTFILES_DIR" ]]; then
        prompt_replace_repo || exit 1
        clone_repo || exit 1
    else
        clone_repo || exit 1
    fi

    init_submodules

    log_info "Launching setup script..."
    echo

    exec "$DOTFILES_DIR/install.zsh" "${PASS_THROUGH_ARGS[@]}"
}

main "$@"
