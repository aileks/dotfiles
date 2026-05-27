#!/bin/bash

set -uo pipefail

readonly LOG_RED='\033[0;31m'
readonly LOG_GREEN='\033[0;32m'
readonly LOG_YELLOW='\033[1;33m'
readonly LOG_BLUE='\033[0;34m'
readonly LOG_NC='\033[0m'

DOTFILES_REPO="https://codeberg.org/aileks/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.config-backup.$(date +%Y%m%d_%H%M%S)"
BACKUP_SUFFIX=".backup.$(date +%Y%m%d_%H%M%S)"

SCRIPT_DIR=""

declare -a SETUP_ERRORS=()

# ============================================================
# Logging
# ============================================================

log_info() { echo -e "${LOG_BLUE}[INFO]${LOG_NC} $1"; }
log_success() { echo -e "${LOG_GREEN}[OK]${LOG_NC} $1"; }
log_warning() { echo -e "${LOG_YELLOW}[WARN]${LOG_NC} $1"; }
log_error() { echo -e "${LOG_RED}[ERROR]${LOG_NC} $1"; }

record_error() {
    log_error "$1"
    SETUP_ERRORS+=("$1")
}

# ============================================================
# Helpers
# ============================================================

command_exists() { command -v "$1" &>/dev/null; }
pacman_installed() { pacman -Q "$1" &>/dev/null; }

prompt_yes_no() {
    local prompt="$1" default="${2:-N}" reply
    if ! read -r -p "$prompt [$default/y]: " reply; then reply="$default"; fi
    reply=${reply:-$default}
    [[ $reply =~ ^[Yy]$ ]]
}

check_os() {
    if ! [[ -r /etc/os-release ]] || ! grep -qiE '^ID=cachyos' /etc/os-release; then
        log_error "Unsupported OS. This script requires CachyOS."
        exit 1
    fi
}

show_help() {
    cat <<EOF
KDE Plasma Dotfiles Installer (CachyOS)

Run modes:
  curl -fsSL https://aileks.dev/arch | bash    # bootstrap from network
  ./setup.sh                                    # run from a local clone

When invoked outside a clone of the dotfiles repo, this script will:
  1. Ensure base packages (git, base-devel) are installed
  2. Clone or update the repo at ~/.dotfiles
  3. Re-exec itself from the cloned location

When invoked from inside a clone, it skips bootstrap and proceeds
straight to package install + symlink wiring.

Flags:
  -h, --help    Show this message
EOF
}

# ============================================================
# Bootstrap (only runs when not already inside a clone)
# ============================================================

ensure_base_packages() {
    log_info "Checking base packages (git, base-devel)..."
    local missing=()
    command_exists git || missing+=("git")
    pacman_installed base-devel || missing+=("base-devel")

    if [[ ${#missing[@]} -eq 0 ]]; then
        log_success "Base packages already installed"
        return 0
    fi

    log_info "Installing: ${missing[*]}"
    if ! sudo pacman -S --needed --noconfirm "${missing[@]}"; then
        log_error "Failed to install base packages"
        exit 1
    fi
    log_success "Base packages installed"
}

verify_dotfiles_repo() {
    [[ -d $DOTFILES_DIR ]] || return 1
    command_exists git || return 1
    pushd "$DOTFILES_DIR" &>/dev/null || return 1
    if ! git rev-parse --git-dir &>/dev/null; then
        popd &>/dev/null || true
        return 1
    fi
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    popd &>/dev/null || true
    [[ $remote_url == *"$DOTFILES_REPO"* || $remote_url == *"aileks/dotfiles"* ]]
}

prompt_replace_repo() {
    local existing_url
    existing_url=$(cd "$DOTFILES_DIR" 2>/dev/null && git remote get-url origin 2>/dev/null || echo "unknown")
    echo
    log_warning "Existing repository found at ~/.dotfiles"
    echo "  Expected: $DOTFILES_REPO"
    echo "  Found:    $existing_url"
    echo
    echo "  1) Backup and replace"
    echo "  2) Cancel"
    while true; do
        read -rp "Choice [1/2]: " choice
        case "$choice" in
        1)
            mv "$DOTFILES_DIR" "${DOTFILES_DIR}${BACKUP_SUFFIX}"
            log_success "Backed up to: ${DOTFILES_DIR}${BACKUP_SUFFIX}"
            return 0
            ;;
        2)
            log_info "Cancelled"
            exit 0
            ;;
        *) log_error "Invalid choice: $choice" ;;
        esac
    done
}

update_existing_repo() {
    log_info "Updating existing dotfiles repository..."
    cd "$DOTFILES_DIR" || return 1
    git fetch origin &>/dev/null || {
        log_warning "Fetch failed, using local"
        cd - &>/dev/null
        return 0
    }
    local branch
    branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
    local local_ref remote_ref
    local_ref=$(git rev-parse HEAD 2>/dev/null || echo "")
    remote_ref=$(git rev-parse "origin/$branch" 2>/dev/null || echo "")
    if [[ $local_ref == "$remote_ref" ]]; then
        log_success "Already up to date"
    else
        git reset --hard "origin/$branch" &>/dev/null
        log_success "Updated to latest"
    fi
    cd - &>/dev/null || true
}

clone_repo() {
    log_info "Cloning dotfiles..."
    local i=1
    while [[ $i -le 3 ]]; do
        if git clone "$DOTFILES_REPO" "$DOTFILES_DIR"; then
            log_success "Cloned"
            return 0
        fi
        log_warning "Clone failed (attempt $i/3)"
        [[ $i -lt 3 ]] && sleep 5
        i=$((i + 1))
    done
    log_error "Failed to clone after 3 attempts"
    return 1
}

resolve_script_dir() {
    local self_path="${BASH_SOURCE[0]:-}"
    local self_dir=""
    if [[ -n $self_path && -f $self_path ]]; then
        self_dir="$(cd "$(dirname "$self_path")" 2>/dev/null && pwd)" || self_dir=""
    fi

    if [[ -n $self_dir && -f "$self_dir/setup.sh" && -d "$self_dir/zsh" ]]; then
        SCRIPT_DIR="$self_dir"
        return 0
    fi

    log_info "Starting Arch bootstrap..."
    ensure_base_packages

    if verify_dotfiles_repo; then
        update_existing_repo || exit 1
    elif [[ -d $DOTFILES_DIR ]]; then
        prompt_replace_repo
        clone_repo || exit 1
    else
        clone_repo || exit 1
    fi

    log_info "Re-launching from cloned repo..."
    echo
    exec bash "$DOTFILES_DIR/setup.sh" "$@" </dev/tty
}

# ============================================================
# Package Lists
# ============================================================

PACMAN_PACKAGES=(
    neovim starship trash-cli shfmt jq
    fastfetch btop eza bat fd ripgrep fzf zoxide
    kitty linux-cachyos-nvidia-open obs-studio
    papirus-icon-theme adw-gtk-theme
    signal-desktop bitwarden zed ddcutil
)

AUR_PACKAGES=(
    zen-browser-bin
    onlyoffice-bin
    fastmail
    notesnook-bin
    kwin-polonium
)

# ============================================================
# Package Installation
# ============================================================

install_pacman_packages() {
    log_info "Refreshing pacman databases..."
    sudo pacman -Sy --noconfirm || record_error "Failed to sync pacman databases"

    log_info "Installing pacman packages..."
    if ! sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"; then
        record_error "Failed to install some pacman packages"
        return 1
    fi
    log_success "pacman packages installed"
}

install_aur_packages() {
    local aur_helper=""
    if command_exists paru; then
        aur_helper="paru"
    elif command_exists yay; then
        aur_helper="yay"
    else
        record_error "No AUR helper found (paru or yay); skipping AUR packages"
        return 1
    fi

    log_info "Installing AUR packages via $aur_helper..."
    if ! $aur_helper -S --needed --noconfirm "${AUR_PACKAGES[@]}"; then
        record_error "Failed to install some AUR packages"
        return 1
    fi
    log_success "AUR packages installed"
}

setup_ddc() {
    if ! pacman_installed ddcutil; then
        log_warning "ddcutil not installed; skipping DDC/CI setup"
        return 0
    fi

    local conf=/etc/modules-load.d/i2c-dev.conf
    if [[ -f $conf ]] && grep -q '^i2c-dev$' "$conf"; then
        log_success "i2c-dev module already configured"
    else
        log_info "Configuring i2c-dev module to load at boot..."
        if printf 'i2c-dev\n' | sudo tee "$conf" >/dev/null; then
            log_success "Wrote $conf"
            sudo modprobe i2c-dev 2>/dev/null || true
        else
            record_error "Failed to write $conf"
        fi
    fi

    if ! getent group i2c >/dev/null; then
        log_info "Creating i2c group..."
        sudo groupadd -r i2c || record_error "Failed to create i2c group"
    fi

    if id -nG "$USER" | grep -qw i2c; then
        log_success "$USER already in i2c group"
    else
        log_info "Adding $USER to i2c group (effective after relog)..."
        if sudo usermod -aG i2c "$USER"; then
            log_success "Added $USER to i2c group"
        else
            record_error "Failed to add $USER to i2c group"
        fi
    fi
}

install_uv() {
    log_info "Setting up uv..."

    if command_exists uv; then
        log_success "uv already installed"
    else
        log_info "Installing uv..."
        if ! curl -LsSf https://astral.sh/uv/install.sh | sh; then
            record_error "Failed to install uv"
        fi
    fi
}

# ============================================================
# Antidote (official install per upstream README)
# ============================================================

install_antidote() {
    local antidote_dir="$HOME/.antidote"
    if [[ -d "$antidote_dir/.git" ]]; then
        log_info "Updating antidote..."
        if git -C "$antidote_dir" pull --ff-only --quiet; then
            log_success "antidote up to date"
        else
            record_error "Failed to update antidote"
        fi
        return 0
    fi
    if [[ -e $antidote_dir ]]; then
        record_error "$antidote_dir exists but is not a git checkout; remove it manually"
        return 1
    fi
    log_info "Cloning antidote..."
    if git clone --depth=1 https://github.com/mattmc3/antidote.git "$antidote_dir"; then
        log_success "antidote installed at $antidote_dir"
    else
        record_error "Failed to clone antidote"
    fi
}

# ============================================================
# Zsh legacy cleanup
# ============================================================

migrate_zsh_legacy() {
    local zplug_dir="$HOME/.zplug"
    local ashen_plugin="$HOME/.zsh/plugins/ashen_zsh_syntax_highlighting.zsh"

    if [[ -d $zplug_dir ]]; then
        log_info "Removing legacy ~/.zplug (replaced by antidote)..."
        rm -rf "$zplug_dir" || record_error "Failed to remove $zplug_dir"
    fi
    if [[ -f $ashen_plugin ]]; then
        log_info "Removing legacy ashen syntax highlighting plugin..."
        rm -f "$ashen_plugin" || record_error "Failed to remove $ashen_plugin"
    fi
}

# ============================================================
# Symlinks
# ============================================================

create_symlink() {
    local source="$1" target="$2"

    if [[ ! -e $source ]]; then
        record_error "Source missing: $source"
        return 1
    fi

    if [[ -L $target && "$(readlink "$target")" == "$source" ]]; then
        log_success "Already linked: $target"
        return 0
    fi

    if [[ -L $target ]]; then
        rm "$target"
    elif [[ -e $target ]]; then
        mkdir -p "$BACKUP_DIR"
        mv "$target" "$BACKUP_DIR/$(basename "$target")"
    fi

    mkdir -p "$(dirname "$target")"
    if ! ln -sf "$source" "$target"; then
        record_error "Failed to link $target -> $source"
    else
        log_success "Linked: $target"
    fi
}

symlink_configs() {
    log_info "Creating config symlinks..."
    mkdir -p "$HOME/.config"

    create_symlink "$SCRIPT_DIR/btop" "$HOME/.config/btop"
    create_symlink "$SCRIPT_DIR/kitty" "$HOME/.config/kitty"
    create_symlink "$SCRIPT_DIR/nvim" "$HOME/.config/nvim"
    create_symlink "$SCRIPT_DIR/zed/settings.json" "$HOME/.config/zed/settings.json"
    create_symlink "$SCRIPT_DIR/zed/keymap.json" "$HOME/.config/zed/keymap.json"
    create_symlink "$SCRIPT_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
    create_symlink "$SCRIPT_DIR/fastfetch" "$HOME/.config/fastfetch"
    create_symlink "$SCRIPT_DIR/bat" "$HOME/.config/bat"
    create_symlink "$SCRIPT_DIR/zsh/zshrc" "$HOME/.zshrc"
}

# ============================================================
# Systemd user units
# ============================================================

install_systemd_units() {
    local src_dir="$SCRIPT_DIR/systemd"
    local dest_dir="$HOME/.config/systemd/user"

    if [[ ! -d $src_dir ]]; then
        log_warning "No systemd/ directory found; skipping user units"
        return 0
    fi

    log_info "Linking systemd user units..."
    mkdir -p "$dest_dir"

    shopt -s nullglob
    local unit_files=("$src_dir"/*.service "$src_dir"/*.target "$src_dir"/*.timer "$src_dir"/*.socket)
    shopt -u nullglob

    if [[ ${#unit_files[@]} -eq 0 ]]; then
        log_warning "systemd/ is empty; skipping"
        return 0
    fi

    local enabled_any=0
    for unit in "${unit_files[@]}"; do
        local name
        name=$(basename "$unit")
        create_symlink "$unit" "$dest_dir/$name"
        enabled_any=1
    done

    if [[ $enabled_any -eq 1 ]]; then
        systemctl --user daemon-reload || record_error "systemctl --user daemon-reload failed"
        for unit in "${unit_files[@]}"; do
            local name
            name=$(basename "$unit")
            [[ $name == *.service ]] || continue
            if systemctl --user is-enabled --quiet "$name" 2>/dev/null; then
                log_success "$name already enabled"
            else
                if ! systemctl --user enable "$name"; then
                    record_error "Failed to enable user unit: $name"
                else
                    log_success "Enabled $name (will start with graphical-session.target)"
                fi
            fi
        done
    fi
}

# ============================================================
# Legacy cleanup
# ============================================================

disable_legacy_user_units() {
    local unit_dir="$HOME/.config/systemd/user"
    for unit in swayidle.service polkit.service swaybg.service; do
        if systemctl --user is-enabled --quiet "$unit" 2>/dev/null; then
            systemctl --user disable --now "$unit" 2>/dev/null || true
            log_success "Disabled legacy unit: $unit"
        fi
        rm -f "$unit_dir/$unit"
    done
    systemctl --user daemon-reload 2>/dev/null || true

    pkill -x polkit-gnome-authentication-agent-1 2>/dev/null || true

    for legacy in niri noctalia waybar mako swaylock fuzzel; do
        local target="$HOME/.config/$legacy"
        if [[ -L $target ]]; then
            rm -f "$target"
            log_success "Removed legacy config symlink: $target"
        fi
    done

    for stale in power-menu; do
        local target="$HOME/.local/bin/$stale"
        if [[ -L $target && ! -e $target ]]; then
            rm -f "$target"
            log_success "Removed stale script symlink: $target"
        fi
    done
}

# ============================================================
# Misc finalization
# ============================================================

setup_shell() {
    log_info "Checking default shell..."
    if [[ $SHELL == *"zsh"* ]]; then
        log_success "Default shell is already zsh"
        return 0
    fi
    if ! chsh -s "$(command -v zsh)"; then
        record_error "Failed to change shell to zsh"
    fi
}

setup_xdg_dirs() {
    if command_exists xdg-user-dirs-update; then
        xdg-user-dirs-update || record_error "Failed to update XDG user dirs"
    fi
}

# ============================================================
# KDE Plasma settings
# ============================================================

setup_kde() {
    if ! command_exists kwriteconfig6; then
        log_warning "kwriteconfig6 not found; skipping KDE settings"
        return 0
    fi

    log_info "Applying KDE Plasma settings..."

    kwriteconfig6 --file kcminputrc --group Mouse --key PointerAcceleration flat
    log_success "Mouse acceleration: flat"

    kwriteconfig6 --file kcminputrc --group Keyboard --key RepeatDelay 250
    kwriteconfig6 --file kcminputrc --group Keyboard --key RepeatRate 50
    log_success "Keyboard repeat: delay=250 rate=50"

    if command_exists kcminit; then
        kcminit kcm_mouse 2>/dev/null || true
    fi
}

# ============================================================
# Main
# ============================================================

main() {
    [[ $# -gt 0 && ($1 == "-h" || $1 == "--help") ]] && {
        show_help
        exit 0
    }

    check_os
    resolve_script_dir "$@"

    echo -e "${LOG_RED}================================================================${LOG_NC}"
    echo -e "${LOG_RED} WARNING: ONE-SHOT DEPLOYMENT INITIATED${LOG_NC}"
    echo -e "${LOG_RED}================================================================${LOG_NC}"
    echo -e "${LOG_YELLOW}This will install packages, enable system services,"
    echo -e "and overwrite your dotfile symlinks.${LOG_NC}"
    echo -e "Source tree: ${LOG_GREEN}$SCRIPT_DIR${LOG_NC}"
    echo

    if ! prompt_yes_no "Proceed?" "N"; then
        log_info "Aborted by user."
        exit 0
    fi

    echo
    log_info "Starting full installation pipeline..."

    install_pacman_packages
    install_aur_packages
    disable_legacy_user_units
    setup_ddc
    install_uv
    setup_xdg_dirs
    install_antidote
    migrate_zsh_legacy
    symlink_configs
    install_systemd_units
    setup_kde
    setup_shell

    echo
    log_success "═══════════════════════════════════════"
    log_success "  Installation script finished!"
    log_success "═══════════════════════════════════════"

    if [[ -d $BACKUP_DIR ]] && [[ "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
        log_info "Old configs backed up to: $BACKUP_DIR"
    fi

    if [[ ${#SETUP_ERRORS[@]} -gt 0 ]]; then
        echo
        echo -e "${LOG_RED}Errors during installation:${LOG_NC}"
        for err in "${SETUP_ERRORS[@]}"; do
            echo -e "  - $err"
        done
        echo -e "${LOG_YELLOW}Review the errors; manual intervention may be needed.${LOG_NC}"
    else
        echo
        log_success "Zero errors encountered. Reboot to pick up KDE Plasma session."
    fi
}

main "$@"
