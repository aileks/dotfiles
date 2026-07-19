#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR=""
readonly DOTFILES_REPO="https://codeberg.org/aileks/dotfiles.git"
readonly GTK_THEME_REPO="https://codeberg.org/aileks/cinder-grove-gtk.git"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
BACKUP_DIR="$HOME/.config-backup.$(date +%Y%m%d_%H%M%S)"
readonly BACKUP_DIR
BACKUP_SUFFIX=".backup.$(date +%Y%m%d_%H%M%S)"
readonly BACKUP_SUFFIX

DRY_RUN=0
TEMP_DIR=""
AUR_HELPER=""

readonly -a PACMAN_PACKAGES=(
  7zip
  adwaita-cursors
  alacritty
  alsa-utils
  avahi
  base-devel
  bat
  bitwarden
  blueman
  bluez
  bluez-utils
  btop
  cava
  cliphist
  cups
  curl
  ddcutil
  dconf
  eza
  egl-wayland
  fastfetch
  fd
  ffmpeg
  ffmpegthumbnailer
  file-roller
  fontconfig
  fuzzel
  fwupd
  fzf
  git
  gnome-disk-utility
  gnome-firmware
  gnome-keyring
  grim
  gst-plugin-pipewire
  gvfs
  gvfs-afc
  gvfs-gphoto2
  gvfs-mtp
  gvfs-nfs
  gvfs-smb
  hunspell-en_us
  hypridle
  hyprland
  hyprlock
  hyprpaper
  hyprpolkitagent
  imv
  jq
  kvantum
  less
  libnotify
  libva-nvidia-driver
  libva-utils
  linux
  linux-firmware
  lua
  man-db
  mesa-utils
  mission-center
  nautilus
  neovim
  network-manager-applet
  networkmanager
  nss-mdns
  noto-fonts
  noto-fonts-emoji
  nvidia-open
  nvidia-settings
  nvidia-utils
  nvm
  nwg-displays
  nwg-look
  openssh
  pavucontrol
  papirus-icon-theme
  pipewire
  pipewire-alsa
  pipewire-pulse
  playerctl
  pnpm
  polkit
  python
  qt5-wayland
  qt6-wayland
  qt6ct
  ripgrep
  rsync
  sane-airscan
  sddm
  shellcheck
  shfmt
  signal-desktop
  slurp
  starship
  sushi
  swaync
  swayosd
  system-config-printer
  tmux
  trash-cli
  adwaita-fonts
  ttf-adwaitamono-nerd
  udisks2
  udiskie
  unzip
  uv
  uwsm
  vulkan-tools
  waybar
  wev
  wget
  wireplumber
  wl-clipboard
  xdg-desktop-portal
  xdg-desktop-portal-gtk
  xdg-desktop-portal-hyprland
  xdg-user-dirs
  xdg-utils
  xorg-xwayland
  ydotool
  zip
  zoxide
  zsh
)

readonly -a AUR_PACKAGES=(
  fastmail
  helium-browser-bin
  localsend-bin
  localsend-nautilus-extension
  tmux-sessionizer-bin
  visual-studio-code-bin
  zsh-antidote
)

readonly -a SYSTEM_SERVICES=(
  NetworkManager.service
  avahi-daemon.service
  bluetooth.service
  cups.service
  sddm.service
  systemd-timesyncd.service
)

readonly -a USER_SERVICES=(
  blueman-applet.service
  capslock-default.service
  cliphist-image.service
  cliphist-text.service
  first-login.service
  hypridle.service
  monitor-setup.service
  nm-applet.service
  swaync.service
  swayosd-server.service
  udiskie.service
  waybar.service
  hyprpaper.service
  hyprpolkitagent.service
  pipewire-pulse.socket
  pipewire.socket
  wireplumber.service
  ydotool.service
)

log() { printf '[ok] %s\n' "$*"; }
info() { printf '[..] %s\n' "$*"; }
warn() { printf '[warn] %s\n' "$*" >&2; }
die() {
  printf '[error] %s\n' "$*" >&2
  exit 1
}

parse_args() {
  local arg
  for arg in "$@"; do
    case "$arg" in
      --dry-run) DRY_RUN=1 ;;
      *) die "unknown option: $arg" ;;
    esac
  done
}

format_command() {
  local arg
  printf '  $'
  for arg in "$@"; do
    printf ' %q' "$arg"
  done
  printf '\n'
}

run_cmd() {
  if ((DRY_RUN)); then
    format_command "$@"
    return 0
  fi
  "$@"
}

run_sudo() {
  if ((DRY_RUN)); then
    format_command sudo "$@"
    return 0
  fi
  sudo "$@"
}

run_pacman() {
  local -a args=("$@")
  local arg has_sync=0
  for arg in "${args[@]}"; do
    [[ $arg == -*S* ]] && has_sync=1
  done
  ((has_sync)) || die "run_pacman only supports sync operations"
  run_sudo pacman "${args[@]}" --needed
}

has_tty() {
  [[ -r /dev/tty && -w /dev/tty ]] && (: </dev/tty) >/dev/null 2>&1
}

create_temp_dir() {
  if ((DRY_RUN)); then
    TEMP_DIR="/tmp/setup-dry-run"
    return 0
  fi
  TEMP_DIR=$(mktemp -d)
  trap 'rm -rf "${TEMP_DIR:-}"' EXIT
}

read_os_release() {
  local os_release="${OS_RELEASE_FILE:-/etc/os-release}"
  [[ -r $os_release ]] || die "missing $os_release"
  # shellcheck disable=SC1090
  source "$os_release"
  [[ ${ID:-} == arch ]] || die "Arch Linux is required"
}

validate_environment() {
  read_os_release
  [[ $(uname -m) == x86_64 ]] || die "x86_64 is required"
  ((EUID != 0)) || die "run as the desktop user, not root"
  [[ -d /run/systemd/system ]] || die "systemd must be running"
  command -v sudo >/dev/null || die "sudo is required"
  getent passwd "$USER" >/dev/null || die "could not resolve user $USER"
}

ensure_git() {
  command -v git >/dev/null && return 0
  info "installing git for bootstrap..."
  run_pacman -Syu --noconfirm git base-devel
  ((DRY_RUN)) || command -v git >/dev/null || die "Git installation failed"
}

verify_dotfiles_repo() {
  local remote
  [[ -d $DOTFILES_DIR ]] || return 1
  git -C "$DOTFILES_DIR" rev-parse --git-dir >/dev/null 2>&1 || return 1
  remote=$(git -C "$DOTFILES_DIR" remote get-url origin 2>/dev/null) || return 1
  [[ $remote == "$DOTFILES_REPO" || $remote == *"aileks/dotfiles"* ]]
}

prompt_replace_repo() {
  local existing_url="unknown" reply
  existing_url=$(git -C "$DOTFILES_DIR" remote get-url origin 2>/dev/null || true)
  existing_url=${existing_url:-unknown}
  warn "existing path is not the expected dotfiles repository: $DOTFILES_DIR"
  printf '  expected: %s\n  found:    %s\n' "$DOTFILES_REPO" "$existing_url" >&2
  has_tty || die "move $DOTFILES_DIR, then retry"
  printf 'Back up and replace it? [y/N] ' >/dev/tty
  IFS= read -r reply </dev/tty || reply=""
  [[ ${reply,,} == y || ${reply,,} == yes ]] || die "cancelled"
  run_cmd mv "$DOTFILES_DIR" "${DOTFILES_DIR}${BACKUP_SUFFIX}"
}

update_dotfiles_repo() {
  local branch local_ref remote_ref
  if ((DRY_RUN)); then
    info "update existing dotfiles repository with a fast-forward merge..."
    return 0
  fi
  if ! git -C "$DOTFILES_DIR" fetch origin; then
    warn "fetch failed; using local checkout"
    return 0
  fi
  branch=$(git -C "$DOTFILES_DIR" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || true)
  branch=${branch#origin/}
  branch=${branch:-main}
  local_ref=$(git -C "$DOTFILES_DIR" rev-parse HEAD)
  remote_ref=$(git -C "$DOTFILES_DIR" rev-parse "origin/$branch" 2>/dev/null || true)
  if [[ -z $remote_ref || $local_ref == "$remote_ref" ]]; then
    return 0
  fi
  if git -C "$DOTFILES_DIR" merge-base --is-ancestor HEAD "origin/$branch"; then
    git -C "$DOTFILES_DIR" merge --ff-only "origin/$branch" ||
      warn "fast-forward failed; using local checkout"
  else
    warn "local checkout diverged; leaving it unchanged"
  fi
}

clone_dotfiles_repo() {
  if ((DRY_RUN)); then
    format_command git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    return 0
  fi
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
}

resolve_script_dir() {
  local self_path="${1:-}" self_dir=""
  if [[ -n $self_path && -f $self_path ]]; then
    self_dir=$(cd "$(dirname "$self_path")" && pwd)
  fi
  if [[ -n $self_dir && -d $self_dir/hypr ]]; then
    SCRIPT_DIR="$self_dir"
    readonly SCRIPT_DIR
    return 0
  fi

  ensure_git
  if verify_dotfiles_repo; then
    update_dotfiles_repo
  elif [[ -e $DOTFILES_DIR || -L $DOTFILES_DIR ]]; then
    prompt_replace_repo
    clone_dotfiles_repo
  else
    clone_dotfiles_repo
  fi
  ((DRY_RUN)) || [[ -d $DOTFILES_DIR/hypr ]] ||
    die "dotfiles checkout is incomplete: $DOTFILES_DIR"
  SCRIPT_DIR="$DOTFILES_DIR"
  readonly SCRIPT_DIR
}

ensure_root_file() {
  local path="$1" content="$2" tmp
  if ((DRY_RUN)); then
    info "write $path"
    return 0
  fi
  tmp="$TEMP_DIR/$(basename "$path").new"
  printf '%s' "$content" >"$tmp"
  if sudo test -f "$path" && sudo cmp --silent "$tmp" "$path"; then
    return 0
  fi
  sudo install -D -o root -g root -m 0644 "$tmp" "$path"
}

backup_target() {
  local target="$1" backup
  backup="$BACKUP_DIR/$(basename "$target")"
  mkdir -p "$BACKUP_DIR"
  if [[ -e $backup || -L $backup ]]; then
    backup="$backup.$(date +%s%N)"
  fi
  mv "$target" "$backup"
  info "backed up $target to $backup"
}

link_path() {
  local source="$1" target="$2"
  if [[ -L $target && $(readlink "$target") == "$source" ]]; then
    return 0
  fi
  if ((DRY_RUN)); then
    info "link $target -> $source"
    return 0
  fi
  [[ -e $source || -L $source ]] || die "missing dotfile source: $source"
  if [[ -e $target || -L $target ]]; then
    backup_target "$target"
  fi
  mkdir -p "$(dirname "$target")"
  ln -s "$source" "$target"
}

install_packages() {
  info "updating Arch and installing official packages..."
  run_pacman -Syu --noconfirm "${PACMAN_PACKAGES[@]}"
}

select_aur_helper() {
  if command -v paru >/dev/null 2>&1; then
    AUR_HELPER=paru
  else
    AUR_HELPER=""
  fi
}

install_paru_bin() {
  local paru_dir="$TEMP_DIR/paru-bin"
  if ((DRY_RUN)); then
    info "installing paru..."
    AUR_HELPER=paru
    return 0
  fi
  has_tty || die "paru-bin bootstrap requires a terminal for PKGBUILD review"
  GPG_TTY=$(tty </dev/tty)
  export GPG_TTY
  git clone https://aur.archlinux.org/paru-bin.git "$paru_dir"
  (
    cd "$paru_dir"
    printf '\nReviewing paru-bin PKGBUILD. Quit the pager to continue.\n' >/dev/tty
    less PKGBUILD </dev/tty >/dev/tty
    makepkg -si </dev/tty
  )
  if ! command -v paru >/dev/null || ! pacman -Qq paru-bin >/dev/null 2>&1; then
    die "paru-bin installation failed"
  fi
  AUR_HELPER=paru
}

install_aur_packages() {
  select_aur_helper
  [[ -n $AUR_HELPER ]] || install_paru_bin
  info "installing desktop applications with $AUR_HELPER..."
  if ((DRY_RUN)); then
    format_command "$AUR_HELPER" -S --needed "${AUR_PACKAGES[@]}"
    return 0
  fi
  has_tty || die "AUR package review requires an interactive terminal"
  GPG_TTY=$(tty </dev/tty)
  export GPG_TTY
  "$AUR_HELPER" -S --needed "${AUR_PACKAGES[@]}" </dev/tty
}

check_display_manager() {
  local manager=""
  if [[ -L /etc/systemd/system/display-manager.service ]]; then
    manager=$(readlink -f /etc/systemd/system/display-manager.service)
  fi
  [[ -z $manager || $manager == */sddm.service ]] ||
    die "another display manager is enabled: $manager"
}

configure_sddm() {
  local autologin
  ((DRY_RUN)) || [[ -r /usr/share/wayland-sessions/hyprland-uwsm.desktop ]] ||
    die 'Hyprland UWSM session entry is missing'
  ((DRY_RUN)) || grep -Eq '^Exec=uwsm start .*hyprland[.]desktop$' \
    /usr/share/wayland-sessions/hyprland-uwsm.desktop ||
    die 'Hyprland UWSM session entry is invalid'
  autologin="[Autologin]
User=$USER
Session=hyprland-uwsm.desktop
Relogin=false
"
  ensure_root_file /etc/sddm.conf.d/10-autologin.conf "$autologin"
}

validate_sddm_pam() {
  ((DRY_RUN)) && return 0
  local file pam_dir="${PAM_DIR:-/etc/pam.d}"
  for file in sddm sddm-autologin sddm-greeter hyprlock; do
    [[ -r $pam_dir/$file ]] || die "missing SDDM PAM file: $pam_dir/$file"
  done
  grep -Eq 'include[[:space:]]+system-login' "$pam_dir/sddm" ||
    die "$pam_dir/sddm does not include system-login"
  grep -Eq 'include[[:space:]]+system-local-login' "$pam_dir/sddm-autologin" ||
    die "$pam_dir/sddm-autologin does not include system-local-login"
  grep -Eq 'auth[[:space:]]+required[[:space:]]+pam_permit[.]so' "$pam_dir/sddm-greeter" ||
    die "$pam_dir/sddm-greeter cannot authenticate the greeter"
  grep -q 'pam_gnome_keyring[.]so' "$pam_dir/sddm" ||
    die "$pam_dir/sddm lacks GNOME Keyring integration"
  grep -q 'pam_gnome_keyring[.]so' "$pam_dir/sddm-autologin" ||
    die "$pam_dir/sddm-autologin lacks GNOME Keyring startup"
}

configure_groups() {
  local group
  for group in i2c input; do
    if ! getent group "$group" >/dev/null; then
      run_sudo groupadd --system "$group"
    fi
    if ! id -nG "$USER" | tr ' ' '\n' | grep -qx "$group"; then
      run_sudo usermod -aG "$group" "$USER"
    fi
  done
}

configure_system_services() {
  info "enabling system services..."
  run_sudo systemctl enable "${SYSTEM_SERVICES[@]}"
}

configure_dotfiles() {
  local config_home="${XDG_CONFIG_HOME:-$HOME/.config}" unit source
  info "linking configuration files..."
  link_path "$SCRIPT_DIR/alacritty" "$config_home/alacritty"
  link_path "$SCRIPT_DIR/bat" "$config_home/bat"
  link_path "$SCRIPT_DIR/btop" "$config_home/btop"
  link_path "$SCRIPT_DIR/cava" "$config_home/cava"
  link_path "$SCRIPT_DIR/fastfetch" "$config_home/fastfetch"
  link_path "$SCRIPT_DIR/fuzzel" "$config_home/fuzzel"
  link_path "$SCRIPT_DIR/hypr" "$config_home/hypr"
  link_path "$SCRIPT_DIR/wallpaper/fantasy-woods.jpg" "$HOME/.local/share/backgrounds/fantasy-woods.jpg"
  link_path "$SCRIPT_DIR/nvim" "$config_home/nvim"
  link_path "$SCRIPT_DIR/qt6ct" "$config_home/qt6ct"
  link_path "$SCRIPT_DIR/swaync" "$config_home/swaync"
  link_path "$SCRIPT_DIR/zsh/zshrc" "$HOME/.zshrc"
  link_path "$SCRIPT_DIR/tmux" "$config_home/tmux"
  link_path "$SCRIPT_DIR/uwsm" "$config_home/uwsm"
  link_path "$SCRIPT_DIR/waybar" "$config_home/waybar"
  link_path "$SCRIPT_DIR/xdg-desktop-portal" "$config_home/xdg-desktop-portal"
  link_path "$SCRIPT_DIR/starship/starship.toml" "$config_home/starship.toml"
  link_path "$SCRIPT_DIR/swayosd" "$config_home/swayosd"

  mkdir -p "$config_home/systemd/user"
  for source in "$SCRIPT_DIR"/systemd/user/*.service; do
    unit=$(basename "$source")
    link_path "$source" "$config_home/systemd/user/$unit"
  done

  for source in "$SCRIPT_DIR"/bin/*; do
    link_path "$source" "$HOME/.local/bin/$(basename "$source")"
  done
}

configure_shell() {
  local current_shell
  current_shell=$(getent passwd "$USER" | cut -d: -f7)
  if [[ $current_shell != /usr/bin/zsh ]]; then
    run_sudo chsh -s /usr/bin/zsh "$USER"
  fi
  run_cmd xdg-user-dirs-update
  run_cmd tms config --paths "$HOME/Projects"
}

enable_user_service() {
  local unit="$1"
  if ((DRY_RUN)); then
    format_command systemctl --user enable "$unit"
    return 0
  fi
  systemctl --user enable "$unit"
}

configure_user_services() {
  local unit
  info "enabling graphical-session services..."
  ((DRY_RUN)) || systemctl --user daemon-reload
  for unit in "${USER_SERVICES[@]}"; do
    enable_user_service "$unit"
  done
}

desktop_id() {
  local candidate
  for candidate in "$@"; do
    if [[ -f /usr/share/applications/$candidate || -f $HOME/.local/share/applications/$candidate ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

configure_gsettings() {
  local schema="org.gnome.desktop.interface"
  if ((DRY_RUN)); then
    info "configure dark appearance, icons, cursor, fonts, and clock..."
    return 0
  fi
  gsettings set "$schema" color-scheme prefer-dark
  gsettings set "$schema" icon-theme Papirus-Dark
  gsettings set "$schema" cursor-theme Adwaita
  gsettings set "$schema" font-name 'Adwaita Sans 11'
  gsettings set "$schema" monospace-font-name 'AdwaitaMono Nerd Font Mono 11'
  gsettings set "$schema" clock-format 24h
  gsettings set org.gnome.desktop.wm.preferences button-layout ''
}

migrate_gtk_config() {
  local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  local data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
  local state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
  local gtk4_css="$config_home/gtk-4.0/gtk.css" target version

  for version in gtk-3.0 gtk-4.0; do
    target="$config_home/$version"
    if [[ -L $target && $(readlink "$target") == "$SCRIPT_DIR/$version" ]]; then
      run_cmd rm "$target"
    fi
  done

  target="$data_home/themes/Cinder-Grove-Dark/gtk-4.0/cinder-grove.css"
  if [[ -f $state_home/cinder-grove-gtk/installed &&
    -f $data_home/themes/Cinder-Grove-Dark/.cinder-grove-theme &&
    ! -e $gtk4_css && ! -L $gtk4_css ]]; then
    run_cmd mkdir -p "$config_home/gtk-4.0"
    run_cmd ln -s "$target" "$gtk4_css"
  fi
}

install_gtk_theme() {
  local theme_dir="$TEMP_DIR/cinder-grove-gtk"
  info "installing Cinder Grove GTK theme..."
  migrate_gtk_config
  run_cmd git clone --depth 1 "$GTK_THEME_REPO" "$theme_dir"
  run_cmd "$theme_dir/install.sh"
}

install_papirus_folders() {
  local installer_url="https://raw.githubusercontent.com/aileks/papirus-folders/cinder-grove-folders/install.sh"
  info "installing Cinder Grove Papirus folders..."
  if ((DRY_RUN)); then
    format_command bash -o pipefail -c \
      "curl -fsSL '$installer_url' | env TAG=cinder-grove-folders sh"
    return 0
  fi
  curl -fsSL "$installer_url" | env TAG=cinder-grove-folders sh
}

configure_papirus() {
  run_cmd papirus-folders-cg --color orange --theme Papirus-Dark
}

configure_default_apps() {
  local browser terminal editor image_viewer mime
  ((DRY_RUN)) && return 0

  browser=$(desktop_id helium.desktop helium-browser.desktop || true)
  terminal=$(desktop_id Alacritty.desktop alacritty.desktop || true)
  editor=$(desktop_id visual-studio-code.desktop code.desktop || true)
  image_viewer=$(desktop_id imv.desktop || true)

  if [[ -n $browser ]]; then
    xdg-settings set default-web-browser "$browser"
    xdg-mime default "$browser" x-scheme-handler/http
    xdg-mime default "$browser" x-scheme-handler/https
    xdg-mime default "$browser" text/html
  else
    warn "Helium desktop entry was not found"
  fi
  xdg-mime default org.gnome.Nautilus.desktop inode/directory
  [[ -z $editor ]] || xdg-mime default "$editor" text/plain
  [[ -z $terminal ]] || xdg-mime default "$terminal" application/x-terminal-emulator
  if [[ -n $image_viewer ]]; then
    for mime in image/x-farbfeld image/tiff image/tiff-fx image/png image/x-png \
      image/jpeg image/jpg image/pjpeg image/svg+xml image/gif image/bmp image/x-bmp \
      image/heif image/avif image/jxl image/webp image/qoi; do
      xdg-mime default "$image_viewer" "$mime"
    done
  else
    warn "imv desktop entry was not found"
  fi
}

install_node_lts() {
  if ((DRY_RUN)); then
    info "install current Node.js LTS with nvm..."
    return 0
  fi
  export NVM_DIR="$HOME/.nvm"
  mkdir -p "$NVM_DIR"
  # shellcheck disable=SC1091
  source /usr/share/nvm/init-nvm.sh
  nvm install --lts
  nvm alias default 'lts/*'
}

configure_ddcutil() {
  run_sudo udevadm control --reload-rules
  run_sudo udevadm trigger --subsystem-match=i2c-dev
  ((DRY_RUN)) || ddcutil detect --brief ||
    warn "DDC/CI monitor control unavailable; enable it in each monitor OSD"
}

run_postflight() {
  if ((DRY_RUN)); then
    format_command "$HOME/.local/bin/doctor"
    return 0
  fi
  "$HOME/.local/bin/doctor"
}

main() {
  parse_args "$@"
  validate_environment
  create_temp_dir
  resolve_script_dir "${BASH_SOURCE[0]:-}"
  ((DRY_RUN)) || sudo -v

  check_display_manager
  install_packages
  install_aur_packages
  configure_sddm
  validate_sddm_pam
  configure_groups
  configure_system_services
  configure_dotfiles
  configure_shell
  configure_user_services
  configure_gsettings
  install_gtk_theme
  install_papirus_folders
  configure_papirus
  configure_default_apps
  install_node_lts
  configure_ddcutil
  run_postflight

  log "Arch Hyprland setup complete"
  info "Reboot, then SDDM will autologin to Hyprland through UWSM!"
}

if [[ -z ${BASH_SOURCE[0]:-} || ${BASH_SOURCE[0]:-} == "$0" ]]; then
  main "$@"
fi
