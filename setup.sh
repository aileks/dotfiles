#!/usr/bin/env bash

set -uo pipefail

readonly LOG_RED=$'\033[0;31m'
readonly LOG_GREEN=$'\033[0;32m'
readonly LOG_YELLOW=$'\033[1;33m'
readonly LOG_BLUE=$'\033[0;34m'
readonly LOG_NC=$'\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" && pwd)"
BACKUP_DIR="$HOME/.config-backup.$(date +%Y%m%d_%H%M%S)"

DOTFILES_REPO="https://codeberg.org/aileks/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

declare -a SETUP_ERRORS=()
declare -a SETUP_NOTES=()

# =====================
# 	Package manifests
# =====================

APT_CORE_PACKAGES=(
  ca-certificates curl rsync git build-essential
  software-properties-common ubuntu-restricted-extras
  vim jq shfmt btop eza bat fd-find ripgrep libopengl0
  fzf zoxide tree pipx flatpak ffmpeg
)

VENDOR_APT_PACKAGES=(
  mise
  wezterm
  code
  signal-desktop
  solaar
)

DOCKER_PACKAGES=(
  docker-ce
  docker-ce-cli
  containerd.io
  docker-buildx-plugin
  docker-compose-plugin
)

# ====================
# 	Logging helpers
# ====================

log_info() { echo -e "${LOG_BLUE}[INFO]${LOG_NC} $1"; }
log_success() { echo -e "${LOG_GREEN}[OK]${LOG_NC} $1"; }
log_warning() { echo -e "${LOG_YELLOW}[WARN]${LOG_NC} $1"; }
log_error() { echo -e "${LOG_RED}[ERROR]${LOG_NC} $1"; }

record_error() {
  log_error "$1"
  SETUP_ERRORS+=("$1")
}

record_note() {
  log_warning "$1"
  SETUP_NOTES+=("$1")
}

command_exists() { command -v "$1" &> /dev/null; }

# ===================
# 	Utility helpers
# ===================

prompt_yes_no() {
  local prompt="$1" default="${2:-N}" reply
  if [[ ! -r /dev/tty ]]; then
    log_warning "No TTY available; using default: $default"
    [[ $default =~ ^[Yy]$ ]]
    return
  fi
  if ! read -r -p "$prompt [$default/y]: " reply < /dev/tty; then reply="$default"; fi
  reply=${reply:-$default}
  [[ $reply =~ ^[Yy]$ ]]
}

apt_install_bundle() {
  if ! sudo DEBIAN_FRONTEND=noninteractive apt install -y "$@"; then
    record_error "Failed to install package bundle: $*"
    return 1
  fi
  return 0
}

apt_install_each() {
  local pkg
  for pkg in "$@"; do
    if dpkg -s "$pkg" &> /dev/null; then
      log_success "$pkg already installed"
      continue
    fi
    if ! sudo DEBIAN_FRONTEND=noninteractive apt install -y "$pkg"; then
      record_error "Failed to install package: $pkg"
    else
      log_success "Installed package: $pkg"
    fi
  done
}

write_root_file() {
  local path="$1" content="$2"
  if ! printf '%s\n' "$content" | sudo tee "$path" > /dev/null; then
    record_error "Failed to write file: $path"
    return 1
  fi
  return 0
}

# =======================================
# 	OS detection and dotfiles bootstrap
# =======================================

check_os() {
  if [[ ! -r /etc/os-release ]]; then
    log_error "Cannot detect OS: /etc/os-release is missing"
    exit 1
  fi

  . /etc/os-release

  if [[ ${ID:-} != "ubuntu" ]]; then
    log_error "Unsupported OS (${ID:-unknown}). This script supports Ubuntu 24.04+ only."
    exit 1
  fi

  if [[ -n ${VERSION_ID:-} ]] && ! dpkg --compare-versions "$VERSION_ID" ge "24.04"; then
    log_error "Unsupported Ubuntu version (${VERSION_ID}). Requires Ubuntu 24.04 or newer."
    exit 1
  fi

  if ! command_exists apt; then
    log_error "apt is required but not available"
    exit 1
  fi
}

bootstrap() {
  log_info "Ensuring git is installed..."
  if ! command_exists git; then
    sudo apt update || {
      log_error "Failed to update apt metadata"
      exit 1
    }
    sudo DEBIAN_FRONTEND=noninteractive apt install -y git || {
      log_error "Failed to install git"
      exit 1
    }
    log_success "git installed"
  else
    log_success "git already installed"
  fi

  if [[ -d $DOTFILES_DIR ]] && git -C "$DOTFILES_DIR" rev-parse --git-dir &> /dev/null; then
    log_info "Updating existing dotfiles repository..."
    git -C "$DOTFILES_DIR" fetch origin &> /dev/null || log_warning "Fetch failed, using local copy"
    local branch local_ref remote_ref
    branch=$(git -C "$DOTFILES_DIR" symbolic-ref refs/remotes/origin/HEAD 2> /dev/null \
      | sed 's@^refs/remotes/origin/@@' || echo "main")
    local_ref=$(git -C "$DOTFILES_DIR" rev-parse HEAD 2> /dev/null || echo "")
    remote_ref=$(git -C "$DOTFILES_DIR" rev-parse "origin/$branch" 2> /dev/null || echo "")
    if [[ $local_ref == "$remote_ref" ]]; then
      log_success "Already up to date"
    else
      git -C "$DOTFILES_DIR" reset --hard "origin/$branch" &> /dev/null
      log_success "Updated to latest"
    fi
  else
    log_info "Cloning dotfiles..."
    local i=1
    while [[ $i -le 3 ]]; do
      if git clone "$DOTFILES_REPO" "$DOTFILES_DIR"; then
        log_success "Cloned"
        break
      fi
      log_warning "Clone failed (attempt $i/3)"
      [[ $i -lt 3 ]] && sleep 5
      i=$((i + 1))
      [[ $i -gt 3 ]] && {
        log_error "Failed to clone after 3 attempts"
        exit 1
      }
    done
  fi

  if [[ $SCRIPT_DIR != "$DOTFILES_DIR" ]]; then
    log_info "Restarting from cloned dotfiles..."
    exec bash "$DOTFILES_DIR/setup.sh" < /dev/tty
  fi
}

# ===============================
# 	Vendor apt repository setup
# ===============================

setup_docker_repo() {
  if dpkg -s docker-ce &> /dev/null; then
    log_success "Docker already installed, skipping repo setup"
    return 0
  fi

  log_info "Configuring Docker official apt repository..."

  sudo DEBIAN_FRONTEND=noninteractive apt remove -y \
    docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc 2> /dev/null || true

  sudo install -m 0755 -d /etc/apt/keyrings || {
    record_error "Failed to create /etc/apt/keyrings"
    return 1
  }

  if ! sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc; then
    record_error "Failed to download Docker GPG key"
    return 1
  fi
  sudo chmod a+r /etc/apt/keyrings/docker.asc || record_error "Failed to chmod Docker key"

  if ! sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null << EOF; then
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
    record_error "Failed to write Docker apt source"
    return 1
  fi

  log_success "Docker repository configured"
}

setup_wezterm_repo() {
  if dpkg -s wezterm &> /dev/null; then
    log_success "WezTerm already installed, skipping repo setup"
    return 0
  fi

  log_info "Configuring WezTerm Fury apt repository..."

  # Switched to /etc/apt/keyrings for consistency
  sudo install -dm 755 /etc/apt/keyrings || {
    record_error "Failed to create /etc/apt/keyrings"
    return 1
  }

  if ! curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg; then
    record_error "Failed to install WezTerm Fury key"
    return 1
  fi

  if ! echo 'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list > /dev/null; then
    record_error "Failed to write WezTerm apt source"
    return 1
  fi

  if ! sudo chmod 644 /etc/apt/keyrings/wezterm-fury.gpg; then
    record_error "Failed to chmod WezTerm keyring"
    return 1
  fi

  log_success "WezTerm repository configured"
}

setup_mise_repo() {
  if dpkg -s mise &> /dev/null; then
    log_success "mise already installed, skipping repo setup"
    return 0
  fi

  log_info "Configuring mise apt repository..."

  sudo install -dm 755 /etc/apt/keyrings || {
    record_error "Failed to create /etc/apt/keyrings"
    return 1
  }

  if ! curl -fSs https://mise.jdx.dev/gpg-key.pub | sudo tee /etc/apt/keyrings/mise-archive-keyring.asc > /dev/null; then
    record_error "Failed to install mise key"
    return 1
  fi

  if ! write_root_file "/etc/apt/sources.list.d/mise.list" \
    "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.asc] https://mise.jdx.dev/deb stable main"; then
    return 1
  fi

  log_success "mise repository configured"
}

setup_vscode_repo() {
  if dpkg -s code &> /dev/null; then
    log_success "VS Code already installed, skipping repo setup"
    return 0
  fi

  log_info "Configuring VS Code apt repository..."

  sudo install -dm 755 /etc/apt/keyrings || {
    record_error "Failed to create /etc/apt/keyrings"
    return 1
  }

  if ! curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --yes --dearmor -o /etc/apt/keyrings/packages.microsoft.gpg; then
    record_error "Failed to install VS Code key"
    return 1
  fi

  if ! write_root_file "/etc/apt/sources.list.d/vscode.list" \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main"; then
    return 1
  fi

  log_success "VS Code repository configured"
}

setup_signal_repo() {
  if dpkg -s signal-desktop &> /dev/null; then
    log_success "Signal already installed, skipping repo setup"
    return 0
  fi

  log_info "Configuring Signal apt repository..."

  sudo install -dm 755 /etc/apt/keyrings || {
    record_error "Failed to create /etc/apt/keyrings"
    return 1
  }

  if ! curl -fsSL https://updates.signal.org/desktop/apt/keys.asc | sudo gpg --yes --dearmor -o /etc/apt/keyrings/signal-desktop-keyring.gpg; then
    record_error "Failed to install Signal key"
    return 1
  fi

  if ! write_root_file "/etc/apt/sources.list.d/signal-xenial.list" \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main"; then
    return 1
  fi

  sudo chmod 644 /etc/apt/keyrings/signal-desktop-keyring.gpg || record_error "Failed to chmod Signal keyring"
  log_success "Signal repository configured"
}

setup_solaar_repo() {
  if dpkg -s solaar &> /dev/null; then
    log_success "Solaar already installed, skipping repo setup"
    return 0
  fi

  log_info "Configuring Solaar PPA repository..."

  if ! sudo DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:solaar-unifying/stable; then
    record_error "Failed to configure Solaar PPA"
    return 1
  fi

  log_success "Solaar PPA repository configured"
}

# ========================
# 	Package installation
# ========================

install_apt_packages() {
  log_info "Refreshing apt metadata..."
  sudo apt update || {
    record_error "Failed to update apt package lists"
    return 1
  }

  log_info "Installing Ubuntu apt packages..."
  apt_install_bundle "${APT_CORE_PACKAGES[@]}"
}

setup_vendor_repositories() {
  setup_docker_repo
  setup_wezterm_repo
  setup_mise_repo
  setup_vscode_repo
  setup_signal_repo
  setup_solaar_repo

  log_info "Refreshing apt metadata after adding vendor repositories..."
  sudo apt update || record_error "Failed to update apt after vendor repos"
}

install_vendor_packages() {
  log_info "Installing vendor-repository packages..."
  apt_install_each "${VENDOR_APT_PACKAGES[@]}"

  log_info "Installing Docker from the official Docker repository..."
  apt_install_bundle "${DOCKER_PACKAGES[@]}"

  if getent group docker &> /dev/null; then
    sudo usermod -aG docker "$USER" || record_note "Could not add $USER to docker group"
    sudo systemctl enable --now docker.service || record_note "Could not enable/start Docker service"
  else
    record_note "Docker group not found; skipping usermod and service enable steps"
  fi

  log_info "Installing Zen Browser (tarball method)..."

  if [[ -f "$HOME/.tarball-installations/zen/zen" ]]; then
    log_success "Zen Browser is already installed"
  else
    if ! curl -fsSL https://github.com/zen-browser/updates-server/raw/refs/heads/main/install.sh | bash > /dev/null; then
      record_error "Failed to install Zen Browser"
    else
      log_success "Zen Browser installed"
    fi
  fi
}

# =======================
# 	Non-apt installers
# =======================

install_script_tools() {
  log_info "Installing tools via official install scripts when needed..."

  if command_exists uv; then
    log_success "uv already installed"
  else
    if ! curl -LsSf https://astral.sh/uv/install.sh | sh; then
      record_error "Failed to install uv"
    else
      log_success "uv installed"
    fi
  fi

  if command_exists starship; then
    log_success "starship already installed"
  else
    if ! curl -sS https://starship.rs/install.sh | sh -s -- -y; then
      record_error "Failed to install starship"
    else
      log_success "starship installed"
    fi
  fi

  if command_exists fastfetch; then
    log_success "fastfetch already installed"
  else
    . /etc/os-release
    if dpkg --compare-versions "${VERSION_ID:-0}" ge "25.10"; then
      log_info "Installing fastfetch from official repos..."
      if ! sudo DEBIAN_FRONTEND=noninteractive apt install -y fastfetch; then
        record_error "Failed to install fastfetch"
      else
        log_success "fastfetch installed"
      fi
    else
      log_info "Adding fastfetch PPA for Ubuntu ${VERSION_ID}..."
      if ! sudo DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:zhangsongcui3371/fastfetch; then
        record_error "Failed to add fastfetch PPA"
      else
        sudo apt update || true
        if ! sudo DEBIAN_FRONTEND=noninteractive apt install -y fastfetch; then
          record_error "Failed to install fastfetch from PPA"
        else
          log_success "fastfetch installed from PPA"
        fi
      fi
    fi
  fi

  if [[ -f "$HOME/.local/share/blesh/ble.sh" ]]; then
    log_success "ble.sh already installed"
  else
    log_info "Installing ble.sh (nightly)..."
    local ble_tmp
    ble_tmp=$(mktemp -d)
    if curl -L https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz \
      | tar xJf - -C "$ble_tmp"; then
      if bash "$ble_tmp/ble-nightly/ble.sh" --install "$HOME/.local/share"; then
        log_success "ble.sh installed to ~/.local/share/blesh"
      else
        record_error "ble.sh install step failed"
      fi
    else
      record_error "Failed to download/extract ble.sh"
    fi
    rm -rf "$ble_tmp"
  fi
}

install_python_utilities() {
  log_info "Installing Python CLI utilities via pipx..."

  if ! command_exists pipx; then
    record_error "pipx is not available"
    return 1
  fi

  pipx ensurepath > /dev/null 2>&1 || true

  if ! pipx install --force trash-cli; then
    record_error "Failed to install trash-cli via pipx"
  else
    log_success "trash-cli installed via pipx"
  fi
}

# ======================
# 	Flatpak & Flathub
# ======================

configure_flatpak() {
  log_info "Configuring Flatpak and Flathub..."

  if ! command_exists flatpak; then
    record_error "flatpak is not installed"
    return 1
  fi

  if ! flatpak remote-list --user --columns=name | grep -qx flathub; then
    if ! flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
      record_error "Failed to add Flathub remote"
      return 1
    fi
  fi

  log_success "Flathub is configured"
}

flatpak_install_app() {
  local app_id="$1"
  if flatpak info "$app_id" &> /dev/null; then
    log_success "Flatpak app already installed: $app_id"
    return 0
  fi

  if ! flatpak install --user -y flathub "$app_id"; then
    record_error "Failed to install flatpak app: $app_id"
    return 1
  fi

  log_success "Installed flatpak app: $app_id"
  return 0
}

install_flatpak_apps() {
  log_info "Installing Flatpak apps from Flathub..."

  flatpak_install_app com.bitwarden.desktop
  flatpak_install_app com.fastmail.Fastmail
  flatpak_install_app com.notesnook.Notesnook
  flatpak_install_app org.onlyoffice.desktopeditors

  log_success "Flatpak app installation complete"
}

# =============================
# 	Snap removal and blocking
# =============================

apply_no_snap_preferences() {
  local pref
  pref="Package: snapd
Pin: release a=*
Pin-Priority: -10"

  write_root_file "/etc/apt/preferences.d/no-snap.pref" "$pref"
}

remove_snaps() {
  if ! prompt_yes_no "Remove snapd and block it from being reinstalled?" "N"; then
    record_note "Skippeed snap removal"
    return 0
  fi

  log_info "Removing and blocking snapd..."

  apply_no_snap_preferences

  if command_exists systemctl; then
    local unit
    for unit in snapd.service snapd.socket snapd.seeded.service; do
      sudo systemctl stop "$unit" 2> /dev/null || true
      sudo systemctl disable "$unit" 2> /dev/null || true
      sudo systemctl mask "$unit" 2> /dev/null || true
    done

    while read -r unit; do
      [[ -z $unit ]] && continue
      sudo systemctl stop "$unit" 2> /dev/null || true
      sudo systemctl disable "$unit" 2> /dev/null || true
      sudo systemctl mask "$unit" 2> /dev/null || true
    done < <(systemctl list-unit-files --type=mount --no-legend 2> /dev/null | awk '/snap/ {print $1}')
  fi

  if command_exists snap; then
    local snap_name
    while read -r snap_name; do
      [[ -z $snap_name ]] && continue
      sudo snap remove --purge "$snap_name" 2> /dev/null || true
    done < <(snap list --all 2> /dev/null | awk 'NR>1 {print $1}' | sort -u)
  fi

  while read -r mount_point; do
    [[ -z $mount_point ]] && continue
    sudo umount -l "$mount_point" 2> /dev/null || sudo umount "$mount_point" 2> /dev/null || true
  done < <(mount | awk '$3 ~ /^\/snap|^\/var\/snap/ {print $3}' | sort -r)

  if dpkg -s snapd &> /dev/null; then
    sudo DEBIAN_FRONTEND=noninteractive apt purge -y snapd 2> /dev/null \
      || sudo DEBIAN_FRONTEND=noninteractive apt remove -y snapd 2> /dev/null \
      || record_error "Failed to remove snapd package"
  fi

  sudo DEBIAN_FRONTEND=noninteractive apt autoremove -y 2> /dev/null || true

  sudo rm -rf /var/cache/snapd /var/lib/snapd /snap /var/snap /root/.snap /root/snap 2> /dev/null || true
  rm -rf "$HOME/.snap" "$HOME/snap" 2> /dev/null || true
  sudo rm -f /etc/apparmor.d/usr.lib.snapd.snap-confine* /etc/apparmor.d/usr.lib.snapd.* 2> /dev/null || true

  if command_exists systemctl; then
    sudo systemctl daemon-reload 2> /dev/null || true
  fi

  log_success "Snap removal and pinning complete"
}

# ====================
# 	Dotfile symlinks
# ====================

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
  create_symlink "$SCRIPT_DIR/wezterm" "$HOME/.config/wezterm"
  create_symlink "$SCRIPT_DIR/fastfetch" "$HOME/.config/fastfetch"
  create_symlink "$SCRIPT_DIR/starship" "$HOME/.config/starship"
  create_symlink "$SCRIPT_DIR/bat" "$HOME/.config/bat"
  create_symlink "$SCRIPT_DIR/bash/bashrc" "$HOME/.bashrc"
  create_symlink "$SCRIPT_DIR/vim/vimrc" "$HOME/.vimrc"
}

# ===============
# 	Entry point
# ===============

main() {
  check_os

  if [[ $SCRIPT_DIR != "$DOTFILES_DIR" ]]; then
    bootstrap
  fi

  echo -e "${LOG_RED}================================================================${LOG_NC}"
  echo -e "${LOG_RED}           WARNING: SYSTEM CHANGES AHEAD${LOG_NC}"
  echo -e "${LOG_RED}================================================================${LOG_NC}"
  echo -e "${LOG_YELLOW}This will install packages, add apt repositories,"
  echo -e "optionally remove snapd, and overwrite dotfile symlinks.${LOG_NC}"
  echo

  if ! prompt_yes_no "Proceed?" "N"; then
    log_info "Aborted by user."
    exit 0
  fi

  echo
  log_info "Starting Ubuntu 24.04+ installation pipeline..."

  log_info "Caching sudo credentials for uninterrupted installation..."
  sudo -v
  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done 2> /dev/null &

  remove_snaps
  install_apt_packages
  setup_vendor_repositories
  install_vendor_packages
  install_script_tools
  install_python_utilities
  configure_flatpak
  install_flatpak_apps
  symlink_configs

  dconf load / < gsetting.dconf

  echo
  log_success "═══════════════════════════════════════"
  log_success " 	   Ubuntu setup finished!"
  log_success "═══════════════════════════════════════"

  if [[ -d $BACKUP_DIR ]] && [[ "$(ls -A "$BACKUP_DIR" 2> /dev/null)" ]]; then
    log_info "Old configs backed up to: $BACKUP_DIR"
  fi

  if [[ ${#SETUP_NOTES[@]} -gt 0 ]]; then
    echo
    echo -e "${LOG_YELLOW}Notes:${LOG_NC}"
    local note
    for note in "${SETUP_NOTES[@]}"; do
      echo -e "  - $note"
    done
  fi

  if [[ ${#SETUP_ERRORS[@]} -gt 0 ]]; then
    echo
    echo -e "${LOG_RED}Errors during installation:${LOG_NC}"
    local err
    for err in "${SETUP_ERRORS[@]}"; do
      echo -e "  - $err"
    done
    echo -e "${LOG_YELLOW}Review the errors; manual intervention may be needed.${LOG_NC}"
  fi
}

main "$@"
