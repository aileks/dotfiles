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
MINIFORGE_PREFIX="$HOME/miniforge3"

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
  if ! [[ -r /etc/os-release ]] || ! grep -qiE '^ID=arch' /etc/os-release; then
    log_error "Unsupported OS. This script requires Arch Linux."
    exit 1
  fi
}

show_help() {
  cat <<EOF
Niri Dotfiles Installer (Arch Linux)

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

# Resolve where the dotfiles tree lives. If we're already running from a
# clone, use that. Otherwise bootstrap a clone at ~/.dotfiles and re-exec
# the copy that lives there (so symlink targets resolve to a real path).
resolve_script_dir() {
  local self_path="${BASH_SOURCE[0]:-}"
  local self_dir=""
  if [[ -n $self_path && -f $self_path ]]; then
    self_dir="$(cd "$(dirname "$self_path")" 2>/dev/null && pwd)" || self_dir=""
  fi

  if [[ -n $self_dir && -d "$self_dir/niri" && -d "$self_dir/zsh" ]]; then
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
  base-devel git curl wget
  zsh tmux vim neovim satty starship
  openssh ufw man-db man-pages
  reflector pacman-contrib
  xdg-user-dirs
  trash-cli shfmt jq
  fastfetch btop eza bat fd ripgrep fzf zoxide

  pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber
  pavucontrol pamixer playerctl
  network-manager-applet blueman

  niri xorg-xwayland xwayland-satellite
  kitty nwg-look
  fuzzel mako swaybg swaylock swayidle
  waybar
  grim slurp wl-clipboard
  xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-gnome
  polkit-gnome
  gnome-keyring
  libnotify gammastep
  brightnessctl
  ly
  tesseract-data-eng

  nvidia-open-dkms nvidia-utils nvidia-settings libva-nvidia-driver
  egl-wayland linux-headers dkms
  xarchiver
  flatpak

  thunar thunar-volman thunar-archive-plugin
  tumbler ffmpegthumbnailer
  
  gvfs gvfs-mtp udiskie
  yazi
  imv qalculate-gtk zathura zathura-pdf-mupdf
  gpu-screen-recorder
  nvtop
  solaar

  noto-fonts noto-fonts-emoji noto-fonts-cjk
  papirus-icon-theme
  qt5ct qt6ct kvantum

  celluloid
  signal-desktop
  bitwarden
  zed
  calcurse
)

AUR_PACKAGES=(
  zen-browser-bin
  onlyoffice-bin
  fastmail
  notesnook-bin
  bemoji
  wiremix
  adw-gtk-theme
  ttf-ms-win10-auto
)

# ============================================================
# Yay (AUR helper)
# ============================================================

install_yay() {
  if command_exists yay; then
    log_success "yay already installed"
    return 0
  fi

  log_info "Installing yay from AUR..."
  local tmpdir
  tmpdir=$(mktemp -d)
  if ! git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"; then
    record_error "Failed to clone yay-bin"
    rm -rf "$tmpdir"
    return 1
  fi

  pushd "$tmpdir/yay-bin" &>/dev/null || return 1
  if ! makepkg -si --noconfirm; then
    record_error "Failed to build/install yay"
    popd &>/dev/null || true
    rm -rf "$tmpdir"
    return 1
  fi
  popd &>/dev/null || true
  rm -rf "$tmpdir"
  log_success "yay installed"
}

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
  if ! command_exists yay; then
    record_error "yay unavailable; skipping AUR packages"
    return 1
  fi

  log_info "Installing AUR packages..."
  if ! yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"; then
    record_error "Failed to install some AUR packages"
    return 1
  fi
  log_success "AUR packages installed"
}

setup_ly() {
  if ! pacman -Q ly &>/dev/null; then
    log_warning "ly not installed; skipping login manager setup"
    return 0
  fi
  log_info "Enabling system services..."
  sudo systemctl disable getty@tty2.service 2>/dev/null || true
  if sudo systemctl enable ly@tty2.service; then
    log_success "ly@tty2.service enabled"
  else
    record_error "Failed to enable ly@tty2.service"
  fi
}

# ============================================================
# Data Tools
# ============================================================

install_data_tools() {
  log_info "Setting up data science tools..."

  if command_exists uv; then
    log_success "uv already installed"
  else
    log_info "Installing uv..."
    if ! curl -LsSf https://astral.sh/uv/install.sh | sh; then
      record_error "Failed to install uv"
    fi
  fi

  if [[ -x "$MINIFORGE_PREFIX/bin/conda" ]]; then
    log_success "Miniforge already installed"
    return 0
  fi

  log_info "Installing Miniforge..."
  local tmpdir installer url
  tmpdir=$(mktemp -d)
  installer="$tmpdir/Miniforge3-$(uname)-$(uname -m).sh"
  url="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"

  if ! curl -L -o "$installer" "$url"; then
    record_error "Failed to download Miniforge installer"
    rm -rf "$tmpdir"
    return 1
  fi

  if bash "$installer" -b -p "$MINIFORGE_PREFIX"; then
    "$MINIFORGE_PREFIX/bin/conda" config --set auto_activate_base false \
      || record_error "Failed to configure conda auto-activate"
    log_success "Miniforge installed"
  else
    record_error "Failed to install Miniforge"
  fi
  rm -rf "$tmpdir"
}

# ============================================================
# NVIDIA: app profiles + modprobe + initramfs modules
# ============================================================

setup_nvidia() {
  local profile_dir=/etc/nvidia/nvidia-application-profiles-rc.d
  local profile_file="$profile_dir/50-limit-free-buffer-pool-in-wayland-compositors.json"

  if [[ -f $profile_file ]]; then
    log_success "NVIDIA niri VRAM profile already present"
  else
    log_info "Installing NVIDIA niri VRAM-mitigation profile..."
    if sudo install -d -m 0755 "$profile_dir" && sudo tee "$profile_file" >/dev/null <<'EOF'; then
{
    "rules": [
        {
            "pattern": {
                "feature": "procname",
                "matches": "niri"
            },
            "profile": "Limit Free Buffer Pool On Wayland Compositors"
        }
    ],
    "profiles": [
        {
            "name": "Limit Free Buffer Pool On Wayland Compositors",
            "settings": [
                {
                    "key": "GLVidHeapReuseRatio",
                    "value": 0
                }
            ]
        }
    ]
}
EOF
      log_success "NVIDIA niri VRAM profile installed"
    else
      record_error "Failed to install NVIDIA niri VRAM profile"
    fi
  fi

  setup_nvidia_modprobe
  setup_nvidia_mkinitcpio
}

setup_nvidia_modprobe() {
  local conf=/etc/modprobe.d/nvidia.conf
  local desired='options nvidia_drm modeset=1 fbdev=1'

  if [[ -f $conf ]] && grep -qE '^[[:space:]]*options[[:space:]]+nvidia_drm[[:space:]]+.*modeset=1' "$conf"; then
    log_success "nvidia_drm modeset already configured ($conf)"
    return 0
  fi

  log_info "Writing $conf (nvidia_drm modeset=1 fbdev=1)..."
  if printf '%s\n' "$desired" | sudo tee "$conf" >/dev/null; then
    log_success "Wrote $conf"
  else
    record_error "Failed to write $conf"
  fi
}

setup_nvidia_mkinitcpio() {
  local conf=/etc/mkinitcpio.conf
  local want='MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)'

  if [[ ! -f $conf ]]; then
    log_warning "$conf not found; skipping initramfs module wiring"
    return 0
  fi

  if grep -qE '^MODULES=\([^)]*nvidia_drm' "$conf"; then
    log_success "nvidia modules already in $conf"
    return 0
  fi

  log_info "Adding nvidia modules to $conf..."
  local backup="${conf}.backup.$(date +%Y%m%d_%H%M%S)"
  if ! sudo cp "$conf" "$backup"; then
    record_error "Failed to back up $conf"
    return 1
  fi
  log_success "Backed up to $backup"

  if ! sudo sed -i -E "s|^MODULES=\([^)]*\)|$want|" "$conf"; then
    record_error "Failed to edit $conf"
    return 1
  fi
  log_success "Updated MODULES in $conf"

  log_info "Rebuilding initramfs (mkinitcpio -P)..."
  if ! sudo mkinitcpio -P; then
    record_error "mkinitcpio -P failed"
    return 1
  fi
  log_success "Initramfs rebuilt"
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

symlink_user_scripts() {
  local src_dir="$SCRIPT_DIR/scripts"
  local dest_dir="$HOME/.local/bin"

  if [[ ! -d $src_dir ]]; then
    log_warning "No scripts/ directory found; skipping user scripts"
    return 0
  fi

  log_info "Linking user scripts to $dest_dir..."
  mkdir -p "$dest_dir"

  shopt -s nullglob
  local linked_any=0
  for f in "$src_dir"/*; do
    [[ -f $f && -x $f ]] || continue
    create_symlink "$f" "$dest_dir/$(basename "$f")"
    linked_any=1
  done
  shopt -u nullglob

  if [[ $linked_any -eq 0 ]]; then
    log_warning "scripts/ contained no executable files"
  fi
}

symlink_configs() {
  log_info "Creating config symlinks..."
  mkdir -p "$HOME/.config"

  create_symlink "$SCRIPT_DIR/niri" "$HOME/.config/niri"
  create_symlink "$SCRIPT_DIR/waybar" "$HOME/.config/waybar"
  create_symlink "$SCRIPT_DIR/mako" "$HOME/.config/mako"
  create_symlink "$SCRIPT_DIR/fuzzel" "$HOME/.config/fuzzel"
  create_symlink "$SCRIPT_DIR/swaylock" "$HOME/.config/swaylock"
  create_symlink "$SCRIPT_DIR/btop" "$HOME/.config/btop"
  create_symlink "$SCRIPT_DIR/kitty" "$HOME/.config/kitty"
  create_symlink "$SCRIPT_DIR/nvim" "$HOME/.config/nvim"
  create_symlink "$SCRIPT_DIR/zed" "$HOME/.config/zed"
  create_symlink "$SCRIPT_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
  create_symlink "$SCRIPT_DIR/fastfetch" "$HOME/.config/fastfetch"
  create_symlink "$SCRIPT_DIR/bat" "$HOME/.config/bat"
  create_symlink "$SCRIPT_DIR/zsh/zshrc" "$HOME/.zshrc"
  create_symlink "$SCRIPT_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
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
# xdg-desktop-portal configuration
# ============================================================

install_portal_config() {
  local src_dir="$SCRIPT_DIR/portals"
  local dest_dir="$HOME/.config/xdg-desktop-portal"

  if [[ ! -d $src_dir ]]; then
    log_warning "No portals/ directory found; skipping portal config"
    return 0
  fi

  log_info "Linking xdg-desktop-portal config..."
  mkdir -p "$dest_dir"

  shopt -s nullglob
  local confs=("$src_dir"/*.conf)
  shopt -u nullglob

  if [[ ${#confs[@]} -eq 0 ]]; then
    log_warning "portals/ is empty; skipping"
    return 0
  fi

  for conf in "${confs[@]}"; do
    create_symlink "$conf" "$dest_dir/$(basename "$conf")"
  done
}

# ============================================================
# Misc finalization
# ============================================================

install_tpm() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [[ -d $tpm_dir ]]; then
    log_success "tpm already installed"
    return 0
  fi
  log_info "Installing Tmux Plugin Manager..."
  mkdir -p "$HOME/.tmux/plugins"
  if ! git clone https://github.com/tmux-plugins/tpm "$tpm_dir"; then
    record_error "Failed to clone tpm"
  fi
}

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
  install_yay
  install_aur_packages
  setup_nvidia
  setup_ly
  install_data_tools
  setup_xdg_dirs
  install_antidote
  migrate_zsh_legacy
  symlink_configs
  symlink_user_scripts
  install_portal_config
  install_systemd_units
  install_tpm
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
    log_success "Zero errors encountered. Reboot to pick up Ly + niri session."
  fi
}

main "$@"
