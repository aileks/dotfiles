#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR=""
readonly DOTFILES_REPO="https://github.com/aileks/dotfiles.git"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
BACKUP_DIR="$HOME/.config-backup.$(date +%Y%m%d_%H%M%S)"
readonly BACKUP_DIR

DRY_RUN=0
TEMP_DIR=""
declare -a FAILURES=()

readonly -a PACMAN_PACKAGES=(
  7zip adwaita-cursors amd-ucode alacritty alsa-utils avahi base-devel
  bat bitwarden blueman bluez bluez-utils btop btrfs-progs cava
  cups curl ddcutil dconf eza egl-wayland fastfetch fd ffmpeg ffmpegthumbnailer
  file-roller fontconfig fwupd fzf gedit geoclue git gnome-disk-utility
  gnome-keyring go gpu-screen-recorder grim gst-plugin-pipewire gvfs gvfs-afc
  gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-smb hunspell-en_us hypridle hyprland
  hyprlock hyprpaper hyprpolkitagent imv inotify-tools jq kvantum less libnotify
  libva-nvidia-driver libva-utils linux linux-firmware lua man-db mesa-utils
  nautilus neovim network-manager-applet networkmanager nss-mdns noto-fonts
  noto-fonts-emoji nvidia-open nvidia-settings nvidia-utils nvm nwg-displays
  nwg-look openssh pavucontrol papirus-icon-theme pipewire pipewire-alsa
  pipewire-pulse playerctl pnpm podman podman-compose podman-docker polkit
  python qt5-wayland qt6-wayland qt6ct ripgrep rsync rtkit satty sddm shellcheck
  signal-desktop snap-pac snapper slurp starship swaync swayosd tmux
  trash-cli adwaita-fonts ttf-adwaitamono-nerd udisks2 udiskie unzip uv uwsm
  vulkan-tools system-config-printer waybar wev wget wireplumber wl-clipboard
  xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xdg-user-dirs
  xdg-utils xorg-xwayland zip zoxide zsh
)

readonly -a AUR_PACKAGES=(
  darkly-bin fastmail helium-browser-bin
  limine-tool limine-snapper-sync localsend-bin
  tmux-sessionizer-bin vicinae-bin zsh-antidote
)

log() { printf '[ok] %s\n' "$*"; }
info() { printf '[..] %s\n' "$*"; }
warn() { printf '[warn] %s\n' "$*" >&2; }
fail() {
  local label="$1" status="${2:-1}"
  printf '[fail] %s (exit %d)\n' "$label" "$status" >&2
  FAILURES+=("$label (exit $status)")
}
die() {
  printf '[error] %s\n' "$*" >&2
  exit 1
}

run_step() {
  local label="$1" status
  shift
  info "$label..."
  "$@" && return 0
  status=$?
  fail "$label" "$status"
  return 0
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

validate_environment() {
  local distro_id os_release="${OS_RELEASE_FILE:-/etc/os-release}"
  [[ -r $os_release ]] || die "missing $os_release"
  # shellcheck disable=SC1090
  source "$os_release"
  distro_id=${ID:-unknown}
  [[ $distro_id == arch ]] || die "Arch Linux is required"
  ((EUID != 0)) || die "run as the desktop user, not root"
  command -v sudo >/dev/null || die "sudo is required"
  getent passwd "$USER" >/dev/null || die "could not resolve user $USER"
  [[ $(uname -m) == x86_64 ]] || die "x86_64 is required"
  [[ -d /run/systemd/system ]] || die "systemd must be running"
}

validate_target_system() {
  local filesystem_root filesystem_type mountpoint
  info "checking target hardware and filesystem layout..."

  [[ -d /sys/firmware/efi ]] || die "UEFI boot is required"
  grep -Fqx 0x10de /sys/bus/pci/devices/*/vendor 2>/dev/null ||
    die "an Nvidia GPU supported by nvidia-open is required"

  for mountpoint in / /home; do
    read -r filesystem_type filesystem_root < <(
      findmnt -nro FSTYPE,FSROOT --mountpoint "$mountpoint"
    ) || die "$mountpoint must be a dedicated Btrfs mount"
    [[ $filesystem_type == btrfs ]] || die "$mountpoint must use Btrfs"
    [[ $filesystem_root != / ]] || die "$mountpoint must mount a Btrfs subvolume"
  done

  filesystem_type=$(findmnt -nro FSTYPE --mountpoint /boot) ||
    die "the EFI system partition must be mounted at /boot"
  [[ $filesystem_type == vfat ]] || die "/boot must be a FAT EFI system partition"
}

ensure_git() {
  command -v git >/dev/null && return 0
  info "installing git for bootstrap..."
  run_pacman -S --noconfirm git base-devel || die "Git installation failed"
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
  run_cmd mv "$DOTFILES_DIR" "${DOTFILES_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
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
  printf '%s' "$content" >"$tmp" || return
  if sudo test -f "$path" && sudo cmp --silent "$tmp" "$path"; then
    return 0
  fi
  sudo install -D -o root -g root -m 0644 "$tmp" "$path"
}

backup_root_file() {
  local source="$1" name="$2"
  local target="/var/backups/aileks-dotfiles/$name"
  if ((DRY_RUN)); then
    info "back up $source to $target if needed"
    return 0
  fi
  sudo test -f "$source" || return 0
  sudo test -e "$target" && return 0
  sudo install -D -o root -g root -m 0600 "$source" "$target"
}

ensure_root_managed_block() {
  local path="$1" begin="$2" end="$3" block="$4" current="" stripped
  if [[ -r $path ]]; then
    current=$(<"$path")
  elif ((DRY_RUN == 0)) && sudo test -r "$path"; then
    current=$(sudo cat "$path")
  fi
  stripped=$(awk -v begin="$begin" -v end="$end" '
    $0 == begin { skip = 1; next }
    $0 == end { skip = 0; next }
    !skip { print }
  ' <<<"$current")
  stripped=${stripped%$'\n'}
  [[ -z $stripped ]] || stripped+=$'\n\n'
  ensure_root_file "$path" "$stripped$begin"$'\n'"$block"$'\n'"$end"$'\n'
}

backup_target() {
  local target="$1" backup
  backup="$BACKUP_DIR/$(basename "$target")"
  mkdir -p "$BACKUP_DIR" || return
  if [[ -e $backup || -L $backup ]]; then
    backup="$backup.$(date +%s%N)"
  fi
  mv "$target" "$backup" || return
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
  if [[ ! -e $source && ! -L $source ]]; then
    fail "link $target: missing source $source"
    return 0
  fi
  if [[ -e $target || -L $target ]]; then
    backup_target "$target" || {
      fail "back up $target" "$?"
      return 0
    }
  fi
  mkdir -p "$(dirname "$target")" || {
    fail "create parent directory for $target" "$?"
    return 0
  }
  ln -s "$source" "$target" || fail "link $target" "$?"
}

remove_managed_link() {
  local source="$1" target="$2"
  if [[ ! -L $target || $(readlink "$target") != "$source" ]]; then
    return 0
  fi
  if ((DRY_RUN)); then
    info "remove obsolete link $target"
    return 0
  fi
  rm "$target" || fail "remove obsolete link $target" "$?"
}

missing_packages() {
  local package
  for package in "$@"; do
    pacman -Qq "$package" >/dev/null 2>&1 || printf '%s\n' "$package"
  done
}

install_paru() {
  local paru_dir="$TEMP_DIR/paru"
  if ((DRY_RUN)); then
    info "installing paru..."
    return 0
  fi
  has_tty || {
    warn "paru bootstrap requires a terminal for PKGBUILD review"
    return 1
  }
  GPG_TTY=$(tty </dev/tty) || return
  export GPG_TTY
  git clone https://aur.archlinux.org/paru.git "$paru_dir" || return
  (
    cd "$paru_dir" || exit
    printf '\nReviewing paru PKGBUILD. Quit the pager to continue.\n' >/dev/tty
    less PKGBUILD </dev/tty >/dev/tty || exit
    makepkg -si </dev/tty
  ) || return
  if ! command -v paru >/dev/null || ! pacman -Qq paru >/dev/null 2>&1; then
    return 1
  fi
}

install_official_packages() {
  local -a missing=()

  mapfile -t missing < <(missing_packages "${PACMAN_PACKAGES[@]}")
  if ((${#missing[@]})); then
    info "installing ${#missing[@]} missing official packages..."
    run_pacman -S --noconfirm "${missing[@]}" || return
  else
    log "all official packages are already installed"
  fi
}

install_aur_packages() {
  local aur_helper=paru
  local -a missing=()

  mapfile -t missing < <(missing_packages "${AUR_PACKAGES[@]}")
  if ((${#missing[@]} == 0)); then
    log "all AUR packages are already installed"
    return 0
  fi
  command -v "$aur_helper" >/dev/null 2>&1 || install_paru || return
  info "installing ${#missing[@]} missing AUR packages with $aur_helper..."
  if ((DRY_RUN)); then
    format_command "$aur_helper" -S --needed "${missing[@]}"
    return 0
  fi
  has_tty || {
    warn "AUR package review requires an interactive terminal"
    return 1
  }
  GPG_TTY=$(tty </dev/tty) || return
  export GPG_TTY
  "$aur_helper" -S --needed "${missing[@]}" </dev/tty
}

configure_mdns() {
  local current path=/etc/nsswitch.conf updated
  current=$(<"$path")
  if grep -Eq '^hosts:.*[[:space:]]mdns(_minimal)?([[:space:]]|$)' <<<"$current"; then
    return 0
  fi
  updated=$(awk '
    /^hosts:/ {
      if ($0 ~ /mymachines/) {
        sub(/mymachines/, "mymachines mdns_minimal [NOTFOUND=return]")
      } else {
        sub(/^hosts:[[:space:]]*/, "&mdns_minimal [NOTFOUND=return] ")
      }
      changed = 1
    }
    { print }
    END { if (!changed) exit 1 }
  ' <<<"$current") || {
    warn "could not configure mDNS in $path"
    return 1
  }
  backup_root_file "$path" nsswitch.conf || return
  ensure_root_file "$path" "$updated"$'\n'
}

snapper_config_exists() {
  local config="$1"
  if ((DRY_RUN)); then
    command -v snapper >/dev/null || return 1
    snapper --csvout --no-headers list-configs 2>/dev/null |
      cut -d, -f1 | grep -Fxq "$config"
    return
  fi
  sudo snapper --csvout --no-headers list-configs |
    cut -d, -f1 | grep -Fxq "$config"
}

ensure_snapper_config() {
  local config="$1" subvolume="$2"
  if snapper_config_exists "$config"; then
    return 0
  fi
  run_sudo snapper -c "$config" create-config "$subvolume"
}

configure_snapper_retention() {
  run_sudo snapper -c root set-config \
    'NUMBER_CLEANUP=yes' \
    'NUMBER_MIN_AGE=3600' \
    'NUMBER_LIMIT=10' \
    'NUMBER_LIMIT_IMPORTANT=10' \
    'TIMELINE_CREATE=no' || return
  run_sudo snapper -c home set-config \
    'TIMELINE_CREATE=no' \
    'TIMELINE_CLEANUP=yes' \
    'TIMELINE_MIN_AGE=3600' \
    'TIMELINE_LIMIT_HOURLY=0' \
    'TIMELINE_LIMIT_DAILY=0' \
    'TIMELINE_LIMIT_WEEKLY=8' \
    'TIMELINE_LIMIT_MONTHLY=0' \
    'TIMELINE_LIMIT_QUARTERLY=0' \
    'TIMELINE_LIMIT_YEARLY=0'
}

configure_mkinitcpio_overlay() {
  local path=/etc/mkinitcpio.conf current updated
  current=$(<"$path")
  if grep -Eq '^[[:space:]]*HOOKS=.*[[:space:](]btrfs-overlayfs([[:space:])]|$)' \
    <<<"$current"; then
    return 0
  fi
  if ! updated=$(awk '
    /^[[:space:]]*HOOKS=\(/ && /filesystems/ {
      sub(/filesystems/, "filesystems btrfs-overlayfs")
      changed = 1
    }
    { print }
    END { if (!changed) exit 1 }
  ' <<<"$current"); then
    warn "could not add btrfs-overlayfs to $path"
    return 1
  fi
  ensure_root_file "$path" "$updated"$'\n'
}

ensure_initial_snapshot() {
  local config="$1" cleanup="$2" description="$3"
  if ((DRY_RUN)); then
    run_sudo snapper -c "$config" create --cleanup-algorithm "$cleanup" \
      --description "$description"
    return 0
  fi
  if sudo snapper --csvout --no-headers -c "$config" list \
    --columns description | grep -Fxq "$description"; then
    return 0
  fi
  sudo snapper -c "$config" create --cleanup-algorithm "$cleanup" \
    --description "$description"
}

configure_snapper() {
  local path unit
  info "reconciling Snapper and Limine recovery..."
  for path in / /home; do
    [[ $(findmnt -no FSTYPE "$path") == btrfs ]] ||
      {
        warn "$path must be a Btrfs filesystem for Snapper"
        return 1
      }
    ((DRY_RUN)) || sudo btrfs subvolume show "$path" >/dev/null ||
      {
        warn "$path must be a Btrfs subvolume for Snapper"
        return 1
      }
  done
  backup_root_file /etc/snapper/configs/root snapper-root.conf || return
  backup_root_file /etc/snapper/configs/home snapper-home.conf || return
  backup_root_file /etc/mkinitcpio.conf mkinitcpio.conf || return
  backup_root_file /etc/default/limine limine-default || return
  backup_root_file /boot/limine.conf limine.conf || return

  ensure_snapper_config root / || return
  ensure_snapper_config home /home || return
  configure_snapper_retention || return
  for unit in snapper-home-weekly.service snapper-home-weekly.timer; do
    ensure_root_file "/etc/systemd/system/$unit" \
      "$(<"$SCRIPT_DIR/systemd/system/$unit")"$'\n' || return
  done
  configure_mkinitcpio_overlay || return
  ensure_root_managed_block /etc/default/limine '# begin aileks snapper setup' \
    '# end aileks snapper setup' 'ESP_PATH="/boot"
ENABLE_UKI=yes
CUSTOM_UKI_NAME="arch"
MKINITCPIO_FALLBACK=no
LIMIT_USAGE_PERCENT=85
MAX_SNAPSHOT_ENTRIES=auto
EXCLUDE_SNAPSHOT_TYPES="post"
SNAPPER_CONFIG_NAME="root"
RESTORE_METHOD=replace
SNAPSHOT_FORMAT_CHOICE=8' || return

  run_sudo systemctl daemon-reload || return
  run_sudo systemctl disable --now snapper-timeline.timer || return
  run_sudo systemctl enable --now snapper-cleanup.timer || return
  run_sudo systemctl enable --now snapper-home-weekly.timer || return
  run_sudo limine-update || return
  run_sudo systemctl enable --now limine-snapper-sync.service || return

  ensure_initial_snapshot root number 'snapper setup' || return
  ensure_initial_snapshot home timeline 'initial weekly home snapshot' || return
  run_sudo limine-snapper-sync || return
  run_sudo limine-snapper-info || return
  ensure_root_file /var/lib/aileks-dotfiles/snapper-v1 $'version=1\n'
}

configure_sddm() {
  local autologin file manager="" pam_dir="${PAM_DIR:-/etc/pam.d}"
  if [[ -L /etc/systemd/system/display-manager.service ]]; then
    manager=$(readlink -f /etc/systemd/system/display-manager.service)
  fi
  if [[ -n $manager && $manager != */sddm.service ]]; then
    warn "another display manager is enabled: $manager"
    return 1
  fi
  ((DRY_RUN)) || [[ -r /usr/share/wayland-sessions/hyprland-uwsm.desktop ]] ||
    {
      warn 'Hyprland UWSM session entry is missing'
      return 1
    }
  ((DRY_RUN)) || grep -Eq '^Exec=uwsm start .*hyprland[.]desktop$' \
    /usr/share/wayland-sessions/hyprland-uwsm.desktop ||
    {
      warn 'Hyprland UWSM session entry is invalid'
      return 1
    }
  autologin="[Autologin]
User=$USER
Session=hyprland-uwsm.desktop
Relogin=false
"
  ensure_root_file /etc/sddm.conf.d/10-autologin.conf "$autologin" || return
  ((DRY_RUN)) && return 0
  for file in sddm sddm-autologin sddm-greeter hyprlock; do
    [[ -r $pam_dir/$file ]] || {
      warn "missing SDDM PAM file: $pam_dir/$file"
      return 1
    }
  done
  grep -Eq 'include[[:space:]]+system-login' "$pam_dir/sddm" ||
    {
      warn "$pam_dir/sddm does not include system-login"
      return 1
    }
  grep -Eq 'include[[:space:]]+system-local-login' "$pam_dir/sddm-autologin" ||
    {
      warn "$pam_dir/sddm-autologin does not include system-local-login"
      return 1
    }
  grep -Eq 'auth[[:space:]]+required[[:space:]]+pam_permit[.]so' "$pam_dir/sddm-greeter" ||
    {
      warn "$pam_dir/sddm-greeter cannot authenticate the greeter"
      return 1
    }
  grep -q 'pam_gnome_keyring[.]so' "$pam_dir/sddm" ||
    {
      warn "$pam_dir/sddm lacks GNOME Keyring integration"
      return 1
    }
  grep -q 'pam_gnome_keyring[.]so' "$pam_dir/sddm-autologin" ||
    {
      warn "$pam_dir/sddm-autologin lacks GNOME Keyring startup"
      return 1
    }
}

configure_suspend_workaround() {
  local content unit
  unit="hyprlock-suspend@$(id -u).service"
  content="$(<"$SCRIPT_DIR/systemd/system/hyprlock-suspend@.service")"$'\n'
  ensure_root_file /etc/systemd/system/hyprlock-suspend@.service "$content" || return
  run_sudo systemctl daemon-reload || return
  run_sudo systemctl enable "$unit"
}

configure_dotfiles() {
  local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  local data_home="${XDG_DATA_HOME:-$HOME/.local/share}" unit source
  info "linking configuration files..."
  link_path "$SCRIPT_DIR/git/.gitconfig" "$HOME/.gitconfig"
  link_path "$SCRIPT_DIR/git/.gitignore_global" "$HOME/.gitignore_global"
  link_path "$SCRIPT_DIR/alacritty" "$config_home/alacritty"
  link_path "$SCRIPT_DIR/bat" "$config_home/bat"
  link_path "$SCRIPT_DIR/btop" "$config_home/btop"
  link_path "$SCRIPT_DIR/cava" "$config_home/cava"
  link_path "$SCRIPT_DIR/fastfetch" "$config_home/fastfetch"
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
  link_path "$SCRIPT_DIR/vicinae/settings.json" "$config_home/vicinae/settings.json"
  link_path "$SCRIPT_DIR/vicinae/themes/cinder-grove.toml" \
    "$data_home/vicinae/themes/cinder-grove.toml"

  remove_managed_link "$SCRIPT_DIR/systemd/user/nm-applet.service" \
    "$config_home/systemd/user/graphical-session.target.wants/nm-applet.service"
  remove_managed_link "$SCRIPT_DIR/systemd/user/nm-applet.service" \
    "$config_home/systemd/user/nm-applet.service"
  remove_managed_link "$SCRIPT_DIR/systemd/user/cliphist-image.service" \
    "$config_home/systemd/user/cliphist-image.service"
  remove_managed_link "$SCRIPT_DIR/systemd/user/cliphist-text.service" \
    "$config_home/systemd/user/cliphist-text.service"
  remove_managed_link "$SCRIPT_DIR/systemd/user/cliphist-image.service" \
    "$config_home/systemd/user/graphical-session.target.wants/cliphist-image.service"
  remove_managed_link "$SCRIPT_DIR/systemd/user/cliphist-text.service" \
    "$config_home/systemd/user/graphical-session.target.wants/cliphist-text.service"
  remove_managed_link "$SCRIPT_DIR/bin/clipboard-menu" "$HOME/.local/bin/clipboard-menu"

  run_cmd mkdir -p "$config_home/systemd/user" || return
  for source in "$SCRIPT_DIR"/systemd/user/*.service; do
    unit=$(basename "$source")
    link_path "$source" "$config_home/systemd/user/$unit"
  done

  for source in "$SCRIPT_DIR"/bin/*; do
    link_path "$source" "$HOME/.local/bin/$(basename "$source")"
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
  gsettings set "$schema" color-scheme prefer-dark || return
  gsettings set "$schema" icon-theme Papirus-Dark || return
  gsettings set "$schema" cursor-theme Adwaita || return
  gsettings set "$schema" font-name 'Adwaita Sans 11' || return
  gsettings set "$schema" monospace-font-name 'AdwaitaMono Nerd Font Mono 11' || return
  gsettings set "$schema" clock-format 24h || return
  gsettings set org.gnome.desktop.wm.preferences button-layout ''
}

install_gtk_theme() {
  local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  local data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
  local state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
  local gtk4_css="$config_home/gtk-4.0/gtk.css"
  local installed_css="$state_home/cinder-grove-gtk/gtk4.css.installed"
  local target theme_dir="$TEMP_DIR/cinder-grove-gtk" version

  for version in gtk-3.0 gtk-4.0; do
    target="$config_home/$version"
    if [[ -L $target && $(readlink "$target") == "$SCRIPT_DIR/$version" ]]; then
      run_cmd rm "$target" || return
    fi
  done

  target="$data_home/themes/Cinder-Grove-Dark/gtk-4.0/cinder-grove.css"
  if [[ -f $state_home/cinder-grove-gtk/installed &&
    -f $data_home/themes/Cinder-Grove-Dark/.cinder-grove-theme ]]; then
    if [[ -f $installed_css ]] &&
      { [[ -L $gtk4_css || ! -f $gtk4_css ]] || ! cmp -s "$gtk4_css" "$installed_css"; }; then
      run_cmd mkdir -p "$config_home/gtk-4.0" || return
      run_cmd rm -f "$gtk4_css" || return
      run_cmd cp "$installed_css" "$gtk4_css" || return
    elif [[ ! -e $gtk4_css && ! -L $gtk4_css ]]; then
      run_cmd mkdir -p "$config_home/gtk-4.0" || return
      run_cmd ln -s "$target" "$gtk4_css" || return
    fi
  fi
  run_cmd git clone --depth 1 https://github.com/aileks/cinder-grove-gtk.git "$theme_dir" || return
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

configure_default_apps() {
  local browser terminal editor image_viewer mime
  ((DRY_RUN)) && return 0

  browser=$(desktop_id helium.desktop helium-browser.desktop || true)
  terminal=$(desktop_id Alacritty.desktop alacritty.desktop || true)
  editor=$(desktop_id org.gnome.gedit.desktop gedit.desktop || true)
  image_viewer=$(desktop_id imv.desktop || true)

  if [[ -n $browser ]]; then
    xdg-settings set default-web-browser "$browser" || return
    xdg-mime default "$browser" x-scheme-handler/http || return
    xdg-mime default "$browser" x-scheme-handler/https || return
    xdg-mime default "$browser" text/html || return
  else
    warn "Helium desktop entry was not found"
  fi
  xdg-mime default org.gnome.Nautilus.desktop inode/directory || return
  [[ -z $editor ]] || xdg-mime default "$editor" text/plain || return
  [[ -z $terminal ]] || xdg-mime default "$terminal" application/x-terminal-emulator || return
  if [[ -n $image_viewer ]]; then
    for mime in image/x-farbfeld image/tiff image/tiff-fx image/png image/x-png \
      image/jpeg image/jpg image/pjpeg image/svg+xml image/gif image/bmp image/x-bmp \
      image/heif image/avif image/jxl image/webp image/qoi; do
      xdg-mime default "$image_viewer" "$mime" || return
    done
  else
    warn "imv desktop entry was not found"
  fi
}

install_node_lts() {
  local default_version lts_version
  export NVM_DIR="$HOME/.nvm"
  [[ -d $NVM_DIR ]] || run_cmd mkdir -p "$NVM_DIR" || return
  # shellcheck disable=SC1091
  source /usr/share/nvm/init-nvm.sh || return
  lts_version=$(nvm version 'lts/*')
  if [[ $lts_version != N/A ]]; then
    log "Node.js LTS is already installed"
  elif ((DRY_RUN)); then
    format_command nvm install --lts
  else
    nvm install --lts || return
    lts_version=$(nvm version 'lts/*')
  fi
  default_version=$(nvm version default 2>/dev/null || true)
  if [[ $default_version != "$lts_version" ]]; then
    if ((DRY_RUN)); then
      format_command nvm alias default 'lts/*'
    else
      nvm alias default 'lts/*'
    fi
  fi
}

main() {
  local arg status unit
  for arg in "$@"; do
    case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    *) die "unknown option: $arg" ;;
    esac
  done
  validate_environment
  validate_target_system
  if ((DRY_RUN)); then
    TEMP_DIR=/tmp/setup-dry-run
  else
    TEMP_DIR=$(mktemp -d) || die "could not create a temporary directory"
    trap 'rm -rf "${TEMP_DIR:-}"' EXIT
  fi
  resolve_script_dir "${BASH_SOURCE[0]:-}"
  ((DRY_RUN)) || sudo -v || die "sudo authentication failed"

  if systemctl --user is-active --quiet cliphist-image.service ||
    systemctl --user is-active --quiet cliphist-text.service; then
    run_step "stop legacy Cliphist services" run_cmd systemctl --user stop \
      cliphist-image.service cliphist-text.service
  fi
  if pacman -Qq cliphist >/dev/null 2>&1; then
    run_step "remove Cliphist" run_sudo pacman -Rns --noconfirm cliphist
  fi

  run_step "install missing official packages" install_official_packages
  run_step "install missing AUR packages" install_aur_packages
  run_step "configure mDNS" configure_mdns
  run_step "configure Snapper and Limine" configure_snapper

  info "configure SDDM..."
  if configure_sddm; then
    run_step "enable sddm.service" run_sudo systemctl enable sddm.service
  else
    status=$?
    fail "configure SDDM" "$status"
  fi

  if ! getent group i2c >/dev/null; then
    run_step "create i2c group" run_sudo groupadd --system i2c
  fi
  if ! id -nG "$USER" | tr ' ' '\n' | grep -qx i2c; then
    run_step "add $USER to i2c group" run_sudo usermod -aG i2c "$USER"
  fi
  run_step "configure suspend lock workaround" configure_suspend_workaround

  for unit in NetworkManager.service avahi-daemon.service bluetooth.service cups.service \
    systemd-timesyncd.service; do
    run_step "enable $unit" run_sudo systemctl enable "$unit"
  done

  run_step "link configuration files" configure_dotfiles
  run_step "build Bat theme cache" run_cmd bat cache --build
  run_step "install Qt color scheme" ensure_root_file \
    /usr/share/qt6ct/colors/cinder-grove.conf \
    "$(<"$SCRIPT_DIR/qt6ct/colors/cinder-grove.conf")"$'\n'

  if [[ $(getent passwd "$USER" | cut -d: -f7) != /usr/bin/zsh ]]; then
    run_step "set Zsh as the login shell" run_sudo chsh -s /usr/bin/zsh "$USER"
  fi
  run_step "update XDG user directories" run_cmd xdg-user-dirs-update
  run_step "configure tmux-sessionizer" run_cmd tms config --paths "$HOME/Projects"

  run_step "reload user services" run_cmd systemctl --user daemon-reload
  for unit in first-login.service hypridle.service monitor-setup.service swaync.service \
    swayosd-server.service udiskie.service waybar.service hyprpaper.service \
    hyprpolkitagent.service pipewire-pulse.socket pipewire.socket podman.socket \
    wireplumber.service; do
    run_step "enable $unit" run_cmd systemctl --user enable "$unit"
  done
  run_step "enable and start vicinae.service" run_cmd systemctl --user enable --now \
    vicinae.service

  run_step "configure desktop appearance" configure_gsettings
  run_step "install Cinder Grove GTK theme" install_gtk_theme
  run_step "install Cinder Grove Papirus folders" install_papirus_folders
  run_step "configure Papirus folders" run_cmd papirus-folders-cg --color orange --theme Papirus-Dark
  run_step "configure default applications" configure_default_apps
  run_step "install Node.js LTS when missing" install_node_lts
  run_step "reload ddcutil rules" run_sudo udevadm control --reload-rules
  run_step "trigger ddcutil devices" run_sudo udevadm trigger --subsystem-match=i2c-dev
  if ((DRY_RUN)); then
    format_command ddcutil detect --brief
  elif ! ddcutil detect --brief; then
    warn "DDC/CI monitor control unavailable; enable it in each monitor OSD"
    fail "detect DDC/CI monitors"
  fi
  run_step "run postflight checks" run_cmd "$HOME/.local/bin/doctor"

  if ((${#FAILURES[@]})); then
    warn "Arch Hyprland setup finished with ${#FAILURES[@]} failure(s):"
    printf '  - %s\n' "${FAILURES[@]}" >&2
  else
    log "Arch Hyprland setup complete"
    info "Reboot, then SDDM will autologin to Hyprland through UWSM!"
  fi
  return 0
}

if [[ -z ${BASH_SOURCE[0]:-} || ${BASH_SOURCE[0]:-} == "$0" ]]; then
  main "$@"
fi
