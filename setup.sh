#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR=""
readonly DOTFILES_REPO="https://github.com/aileks/dotfiles.git"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
readonly MITISHELL_REPO="aileks/mitishell"
readonly MITISHELL_ARCH="amd64"
BACKUP_DIR="$HOME/.config-backup.$(date +%Y%m%d_%H%M%S)"
readonly BACKUP_DIR

DRY_RUN=0
TEMP_DIR=""
declare -a FAILURES=()

readonly -a PACMAN_PACKAGES=(
  7zip adwaita-cursors adwaita-fonts amd-ucode alsa-utils avahi base-devel bat bitwarden jq bluez bluez-utils btop cava cups cuda cudnn curl ddcutil
  dconf duckdb eza egl-wayland fastfetch fd ffmpeg ffmpegthumbnailer file-roller fontconfig fuse-overlayfs fwupd fzf git gnome-disk-utility gnome-keyring
  go lua mise gpu-screen-recorder grim gst-plugin-pipewire gvfs gvfs-afc gvfs-mtp gvfs-gphoto2 gvfs-nfs gvfs-smb hunspell-en_us hypridle hyprland hyprlock
  hyprpaper hyprpicker hyprpolkitagent hyprsunset hyprshutdown imv kitty kvantum lazygit less libnotify inotify-tools libva-utils linux-firmware man-db
  nautilus neovim networkmanager nss-mdns openssh pacman-contrib noto-fonts papers noto-fonts-cjk podman noto-fonts-emoji pipewire papirus-icon-theme
  playerctl nwg-look pipewire-alsa pipewire-pulse polkit qt5-wayland podman-compose podman-docker postgresql-libs qt6-wayland ufw tmux python qt6ct
  quickshell ripgrep rsync rtkit signal-desktop snap-pac snapper slurp socat sqlite starship trash-cli power-profiles-daemon udiskie unzip uv uwsm
  wireplumber wl-clipboard xdg-desktop-portal xdg-desktop-portal-gtk xdg-utils xdg-user-dirs system-config-printer xdg-desktop-portal-hyprland zip
  xorg-xwayland zip zbar zoxide zsh vulkan-icd-loader vulkan-tools wtype otf-latin-modern tesseract celluloid tesseract-data-eng frameworkintegration
  qalculate-gtk tree-sitter-cli otf-latinmodern-math mesa-utils
)

readonly -a AUR_PACKAGES=(
  darkly-bin fastmail zen-browser-twilight-bin tensaku-bin limine-tool limine-snapper-sync localsend tmux-sessionizer-bin zsh-antidote cliamp-bin
  voxtype-bin maplemono-ttf maplemono-nf
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

prompt_step() {
  local label="$1" answer=""
  shift
  if ((! DRY_RUN)) && [[ -r /dev/tty && -w /dev/tty ]]; then
    printf '[ask] %s? [Y/n] ' "$label" >&2
    IFS= read -r answer </dev/tty || answer=""
  fi
  case "${answer:-y}" in
    [nN]*) info "skipping: $label" && return 0 ;;
  esac
  run_step "$label" "$@"
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

  for mountpoint in / /home; do
    read -r filesystem_type filesystem_root < <(
      findmnt -nro FSTYPE,FSROOT --mountpoint "$mountpoint"
    ) || die "$mountpoint must be a dedicated Btrfs mount"
    [[ $filesystem_type == btrfs ]] || die "$mountpoint must use Btrfs"
    [[ $filesystem_root != / ]] || die "$mountpoint must mount a Btrfs subvolume"
  done

  filesystem_type=$(findmnt -nro FSTYPE --mountpoint /boot) \
    || die "the EFI system partition must be mounted at /boot"
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
    git -C "$DOTFILES_DIR" merge --ff-only "origin/$branch" \
      || warn "fast-forward failed; using local checkout"
  else
    warn "local checkout diverged; leaving it unchanged"
  fi
}

clone_dotfiles_repo() {
  if ((DRY_RUN)); then
    format_command git clone --recurse-submodules "$DOTFILES_REPO" "$DOTFILES_DIR"
    return 0
  fi
  git clone --recurse-submodules "$DOTFILES_REPO" "$DOTFILES_DIR"
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
  ((DRY_RUN)) || [[ -d $DOTFILES_DIR/hypr ]] \
    || die "dotfiles checkout is incomplete: $DOTFILES_DIR"
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

ensure_user_file() {
  local path="$1" content="$2" tmp
  if ((DRY_RUN)); then
    info "write $path"
    return 0
  fi
  tmp=$(mktemp "$TEMP_DIR/user-file.XXXXXX") || return
  printf '%s' "$content" >"$tmp" || return
  if [[ -f $path && ! -L $path ]] && cmp --silent "$tmp" "$path"; then
    return 0
  fi
  if [[ -e $path || -L $path ]]; then
    backup_target "$path" || return
  fi
  install -D -m 0644 "$tmp" "$path"
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

missing_packages() {
  local package
  for package in "$@"; do
    pacman -Qq "$package" >/dev/null 2>&1 || printf '%s\n' "$package"
  done
}

install_yay() {
  local yay_dir="$TEMP_DIR/yay"
  if ((DRY_RUN)); then
    info "installing yay..."
    return 0
  fi
  has_tty || {
    warn "yay bootstrap requires a terminal for PKGBUILD review"
    return 1
  }
  GPG_TTY=$(tty </dev/tty) || return
  export GPG_TTY
  git clone https://aur.archlinux.org/yay.git "$yay_dir" || return
  (
    cd "$yay_dir" || exit
    printf '\nReviewing yay PKGBUILD. Quit the pager to continue.\n' >/dev/tty
    less PKGBUILD </dev/tty >/dev/tty || exit
    makepkg -si </dev/tty
  ) || return
  yay_is_available
}

yay_is_available() {
  command -v yay >/dev/null 2>&1 && yay --version >/dev/null 2>&1
}

ensure_yay() {
  if yay_is_available; then
    log "yay is already installed"
    return 0
  fi
  install_yay
}

install_official_packages() {
  local -a packages=("${PACMAN_PACKAGES[@]}") missing=()

  if grep -Fqx 0x10de /sys/bus/pci/devices/*/vendor 2>/dev/null; then
    packages+=(nvidia-open nvidia-utils libva-nvidia-driver)
  fi
  mapfile -t missing < <(missing_packages "${packages[@]}")
  if ((${#missing[@]})); then
    info "installing ${#missing[@]} missing official packages..."
    run_pacman -S --noconfirm "${missing[@]}" || return
  else
    log "all official packages are already installed"
  fi
}

install_aur_packages() {
  local aur_helper=yay
  local -a missing=()

  if ((DRY_RUN == 0)) && ! yay_is_available; then
    warn "yay is required to install AUR packages"
    return 1
  fi
  mapfile -t missing < <(missing_packages "${AUR_PACKAGES[@]}")
  if ((${#missing[@]} == 0)); then
    log "all AUR packages are already installed"
    return 0
  fi
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

mitishell_is_current() {
  local latest_tag=$1
  local data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
  local state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
  local marker="$state_home/dotfiles/mitishell-version"
  [[ -x $HOME/.local/bin/mitishell ]] || return 1
  [[ -f $data_home/mitishell/shell/shell.qml ]] || return 1
  [[ -f $data_home/applications/mitishell.desktop ]] || return 1
  [[ -r $marker ]] || return 1
  grep -Fxq "$latest_tag" "$marker"
}

mitishell_resolve_latest_tag() {
  curl -fsSL "https://api.github.com/repos/$MITISHELL_REPO/releases/latest" \
    | jq -r '.tag_name // empty'
}

install_mitishell() {
  local state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
  local marker="$state_home/dotfiles/mitishell-version"
  local latest_tag base_url archive package

  info "resolving latest Mitishell release..."
  latest_tag=$(mitishell_resolve_latest_tag) || {
    warn "could not resolve latest Mitishell release"
    return 1
  }
  [[ -n $latest_tag ]] || {
    warn "could not resolve latest Mitishell release"
    return 1
  }
  base_url="https://github.com/$MITISHELL_REPO/releases/download/$latest_tag"
  archive="mitishell-$latest_tag-linux-$MITISHELL_ARCH.tar.gz"
  package="mitishell-$latest_tag-linux-$MITISHELL_ARCH"

  if mitishell_is_current "$latest_tag"; then
    log "Mitishell $latest_tag is already installed"
    return 0
  fi
  info "installing Mitishell $latest_tag..."
  if ((DRY_RUN)); then
    format_command curl -fL "$base_url/SHA256SUMS" -o "$TEMP_DIR/SHA256SUMS"
    format_command curl -fL "$base_url/$archive" -o "$TEMP_DIR/$archive"
    format_command sha256sum -c SHA256SUMS --ignore-missing
    format_command tar -xzf "$TEMP_DIR/$archive" -C "$TEMP_DIR"
    format_command make -C "$TEMP_DIR/$package" install-prebuilt
    info "write $marker"
    return 0
  fi
  curl -fL "$base_url/SHA256SUMS" -o "$TEMP_DIR/SHA256SUMS" || return
  curl -fL "$base_url/$archive" -o "$TEMP_DIR/$archive" || return
  (cd "$TEMP_DIR" && sha256sum -c SHA256SUMS --ignore-missing --status) || {
    warn "Mitishell archive checksum mismatch"
    return 1
  }
  tar -xzf "$TEMP_DIR/$archive" -C "$TEMP_DIR" || return
  make -C "$TEMP_DIR/$package" install-prebuilt || return
  mkdir -p "$(dirname "$marker")" || return
  printf '%s\n' "$latest_tag" >"$marker"
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

configure_default_keyring() {
  local keyring_dir="$HOME/.local/share/keyrings"
  local keyring_file="$keyring_dir/Default_keyring.keyring"
  local default_file="$keyring_dir/default"
  local keyring_content default_content='Default_keyring'

  keyring_content="[keyring]
display-name=Default keyring
ctime=$(date +%s)
mtime=0
lock-on-idle=false
lock-after=false
"
  if ((DRY_RUN)); then
    info "provision passwordless default keyring when missing"
    return 0
  fi
  mkdir -p "$keyring_dir" || return
  if [[ ! -f $keyring_file ]]; then
    printf '%s' "$keyring_content" >"$keyring_file" || return
  fi
  if [[ ! -f $default_file ]] || [[ $(<"$default_file") != "$default_content" ]]; then
    if [[ -e $default_file || -L $default_file ]]; then
      backup_target "$default_file" || return
    fi
    printf '%s\n' "$default_content" >"$default_file" || return
  fi
  chmod 700 "$keyring_dir" || return
  chmod 600 "$keyring_file" || return
  chmod 644 "$default_file"
}

configure_ssh_keepalive() {
  local path=/etc/ssh/ssh_config.d/20-aileks-keepalive.conf
  local content='Host *
  ServerAliveInterval 15
  ServerAliveCountMax 3
  ConnectTimeout 10
'
  backup_root_file "$path" ssh-keepalive.conf || return
  ensure_root_file "$path" "$content"
}

configure_firewall() {
  local status=""
  ((DRY_RUN)) || status=$(sudo ufw status 2>/dev/null) || status=""
  if [[ $status == *53317* ]]; then
    log "UFW is already configured"
    return 0
  fi
  run_sudo ufw default deny incoming || return
  run_sudo ufw default allow outgoing || return
  run_sudo ufw allow 53317/udp comment LocalSend || return
  run_sudo ufw allow 53317/tcp comment LocalSend || return
  run_sudo ufw --force enable || return
  run_sudo systemctl enable ufw.service
}

configure_oomd() {
  local path=/etc/systemd/oomd.conf.d/10-aileks.conf
  local content='[OOM]
DefaultMemoryPressureDurationSec=20s
DefaultMemoryPressureLimit=50%
SwapUsedLimit=90%
'
  backup_root_file "$path" oomd.conf || return
  ensure_root_file "$path" "$content" || return
  run_sudo systemctl daemon-reload || return
  run_sudo systemctl enable systemd-oomd.service
}

snapper_config_exists() {
  local config="$1"
  if ((DRY_RUN)); then
    command -v snapper >/dev/null || return 1
    snapper --csvout --no-headers list-configs 2>/dev/null \
      | cut -d, -f1 | grep -Fxq "$config"
    return
  fi
  sudo snapper --csvout --no-headers list-configs \
    | cut -d, -f1 | grep -Fxq "$config"
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
    [[ $(findmnt -no FSTYPE "$path") == btrfs ]] \
      || {
        warn "$path must be a Btrfs filesystem for Snapper"
        return 1
      }
    ((DRY_RUN)) || sudo btrfs subvolume show "$path" >/dev/null \
      || {
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
LIMIT_USAGE_PERCENT=65
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

configure_autologin() {
  local dropin
  if [[ -e /etc/systemd/system/display-manager.service || -L /etc/systemd/system/display-manager.service ]]; then
    warn 'a display manager is still enabled; disable it so tty1 autologin takes effect'
  fi
  ((DRY_RUN)) || [[ -r /usr/share/wayland-sessions/hyprland.desktop ]] \
    || {
      warn 'Hyprland session entry is missing'
      return 1
    }
  ((DRY_RUN)) || grep -Eq 'include[[:space:]]+system-local-login' /etc/pam.d/login \
    || {
      warn '/etc/pam.d/login does not include system-local-login'
      return 1
    }
  dropin="[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --noreset --noclear --autologin $USER - \${TERM}
Type=simple
"
  ensure_root_file /etc/systemd/system/getty@tty1.service.d/autologin.conf "$dropin" || return
  ((DRY_RUN)) && return 0
  run_sudo systemctl daemon-reload || return
  if [[ $(systemctl get-default) != graphical.target ]]; then
    run_sudo systemctl set-default graphical.target || return
  fi
}

configure_uwsm_autostart() {
  local profile="$HOME/.zprofile"
  local block='if uwsm check may-start -q; then
  exec uwsm start hyprland.desktop
fi
'
  if [[ -f $profile ]] && grep -q 'uwsm check may-start' "$profile"; then
    return 0
  fi
  if ((DRY_RUN)); then
    info "write UWSM autostart block to $profile"
    return 0
  fi
  if [[ -s $profile && -n $(tail -c 1 "$profile") ]]; then
    printf '\n' >>"$profile"
  fi
  printf '%s' "$block" >>"$profile"
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
  local unit source
  info "linking configuration files..."

  link_path "$SCRIPT_DIR/kitty" "$config_home/kitty"
  link_path "$SCRIPT_DIR/bat" "$config_home/bat"
  link_path "$SCRIPT_DIR/btop" "$config_home/btop"
  link_path "$SCRIPT_DIR/cava" "$config_home/cava"
  link_path "$SCRIPT_DIR/fastfetch" "$config_home/fastfetch"
  link_path "$SCRIPT_DIR/hypr" "$config_home/hypr"
  link_path "$SCRIPT_DIR/wallpaper/fantasy-woods.jpg" "$HOME/.local/share/backgrounds/fantasy-woods.jpg"
  link_path "$SCRIPT_DIR/mitishell" "$config_home/mitishell"
  link_path "$SCRIPT_DIR/nvim" "$config_home/nvim"
  link_path "$SCRIPT_DIR/qt6ct" "$config_home/qt6ct"
  link_path "$SCRIPT_DIR/fontconfig" "$config_home/fontconfig"
  link_path "$SCRIPT_DIR/zsh/zshrc" "$HOME/.zshrc"
  link_path "$SCRIPT_DIR/tmux" "$config_home/tmux"
  link_path "$SCRIPT_DIR/uwsm" "$config_home/uwsm"
  link_path "$SCRIPT_DIR/voxtype" "$config_home/voxtype"
  link_path "$SCRIPT_DIR/xdg-desktop-portal" "$config_home/xdg-desktop-portal"
  link_path "$SCRIPT_DIR/starship/starship.toml" "$config_home/starship.toml"
  link_path "$SCRIPT_DIR/rsync-home.excludes" "$config_home/rsync-home.excludes"
  link_path "$SCRIPT_DIR/containers/storage.conf" "$config_home/containers/storage.conf"

  run_cmd mkdir -p "$config_home/containers/systemd" || return
  for source in "$SCRIPT_DIR"/containers/systemd/*.container \
    "$SCRIPT_DIR"/containers/systemd/*.volume; do
    link_path "$source" "$config_home/containers/systemd/$(basename "$source")"
  done

  run_cmd mkdir -p "$config_home/systemd/user" || return
  link_path "$SCRIPT_DIR/systemd/user/app.slice.d/10-oomd.conf" \
    "$config_home/systemd/user/app.slice.d/10-oomd.conf"
  link_path "$SCRIPT_DIR/systemd/user/voxtype.service.d/10-nvidia.conf" \
    "$config_home/systemd/user/voxtype.service.d/10-nvidia.conf"
  for source in "$SCRIPT_DIR"/systemd/user/*.service "$SCRIPT_DIR"/systemd/user/*.timer; do
    unit=$(basename "$source")
    link_path "$source" "$config_home/systemd/user/$unit"
  done

  for source in "$SCRIPT_DIR"/bin/*; do
    link_path "$source" "$HOME/.local/bin/$(basename "$source")"
  done
}

configure_voxtype() {
  if ((DRY_RUN == 0)) && ! command -v voxtype >/dev/null; then
    warn 'voxtype is not installed'
    return 1
  fi

  # Omarchy's integration downloads the configured model, selects the GPU
  # backend, and enables the package-owned user service. Pin selection to Nvidia
  # because auto-detection prefers the AMD iGPU on this dual-GPU machine.
  run_cmd voxtype setup --download --no-post-install || return
  run_sudo env VOXTYPE_VULKAN_DEVICE=nvidia voxtype setup gpu --enable || return
  run_cmd systemctl --user daemon-reload || return

  if ((DRY_RUN)); then
    format_command systemctl --user enable --now voxtype.service
  elif systemctl --user is-active --quiet graphical-session.target; then
    systemctl --user enable --now voxtype.service || return
    systemctl --user restart voxtype.service
  else
    systemctl --user enable voxtype.service
  fi
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
  gsettings set "$schema" gtk-theme Cinder-Grove-Dark || return
  gsettings set "$schema" icon-theme Papirus-Dark || return
  gsettings set "$schema" cursor-theme Adwaita || return
  gsettings set "$schema" cursor-size 24 || return
  gsettings set "$schema" font-name 'Adwaita Mono 11' || return
  gsettings set "$schema" monospace-font-name 'Maple Mono NF 11' || return
  gsettings set "$schema" font-antialiasing rgba || return
  gsettings set "$schema" font-hinting slight || return
  gsettings set "$schema" font-rgba-order rgb || return
  gsettings set "$schema" clock-format 24h || return
  gsettings set org.gnome.desktop.wm.preferences button-layout ''
}

install_gtk_theme() {
  local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  local data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
  local state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
  local gtk4_css="$config_home/gtk-4.0/gtk.css"
  local state_dir="$state_home/cinder-grove-gtk"
  local installed_css="$state_dir/gtk4.css.installed"
  local target theme_dir="$TEMP_DIR/cinder-grove-gtk" version

  for version in gtk-3.0 gtk-4.0; do
    target="$config_home/$version"
    if [[ -L $target && $(readlink "$target") == "$SCRIPT_DIR/$version" ]]; then
      run_cmd rm "$target" || return
    fi
  done

  target="$data_home/themes/Cinder-Grove-Dark/gtk-4.0/cinder-grove.css"
  if [[ -f $state_dir/installed &&
    -f $data_home/themes/Cinder-Grove-Dark/.cinder-grove-theme ]]; then
    if [[ -f $installed_css ]] \
      && { [[ -L $gtk4_css || ! -f $gtk4_css ]] || ! cmp -s "$gtk4_css" "$installed_css"; }; then
      run_cmd mkdir -p "$config_home/gtk-4.0" || return
      run_cmd rm -f "$gtk4_css" || return
      run_cmd cp "$installed_css" "$gtk4_css" || return
    elif [[ ! -e $gtk4_css && ! -L $gtk4_css ]]; then
      run_cmd mkdir -p "$config_home/gtk-4.0" || return
      run_cmd ln -s "$target" "$gtk4_css" || return
    fi
    log "Cinder Grove GTK theme is already installed"
    return 0
  fi
  if [[ -e $state_dir || -L $state_dir ]]; then
    if ((DRY_RUN)); then
      info "back up incomplete Cinder Grove GTK state at $state_dir"
    else
      backup_target "$state_dir" || return
    fi
  fi
  run_cmd git clone https://github.com/aileks/cinder-grove-gtk.git "$theme_dir" || return
  if ((DRY_RUN)); then
    info "install Cinder Grove GTK theme with orange accent"
    return 0
  fi
  if [[ -e $data_home/themes/Cinder-Grove-Dark || -L $data_home/themes/Cinder-Grove-Dark ||
    -e $gtk4_css || -L $gtk4_css ]]; then
    printf 'y\norange\n' | "$theme_dir/install.sh"
  else
    printf 'orange\n' | "$theme_dir/install.sh"
  fi
}

install_papirus_folders() {
  local source="$TEMP_DIR/papirus-folders"
  info "installing Cinder Grove Papirus folders..."
  run_cmd git clone --branch cinder-grove-folders --single-branch \
    https://github.com/aileks/papirus-folders.git "$source" || return
  run_cmd env TAG=cinder-grove-folders sh "$source/install.sh" || return
  run_cmd papirus-folders-cg --color grove --theme Papirus-Dark
}

configure_default_apps() {
  local browser terminal editor image_viewer mail_client media_player papers mime
  ((DRY_RUN)) && return 0

  browser=$(desktop_id zen.desktop zen-browser.desktop || true)
  terminal=$(desktop_id kitty.desktop || true)
  editor=$(desktop_id org.gnome.gedit.desktop gedit.desktop || true)
  image_viewer=$(desktop_id imv.desktop || true)
  mail_client=$(desktop_id fastmail.desktop || true)
  media_player=$(desktop_id io.github.celluloid_player.Celluloid.desktop || true)
  papers=$(desktop_id org.gnome.Papers.desktop || true)

  if [[ -n $browser ]]; then
    xdg-settings set default-web-browser "$browser" || return
    xdg-mime default "$browser" x-scheme-handler/http || return
    xdg-mime default "$browser" x-scheme-handler/https || return
    xdg-mime default "$browser" text/html || return
  else
    warn "Zen Browser desktop entry was not found"
  fi
  if [[ -n $mail_client ]]; then
    xdg-mime default "$mail_client" x-scheme-handler/mailto || return
  else
    warn "Fastmail desktop entry was not found"
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
  if [[ -n $media_player ]]; then
    while IFS= read -r mime; do
      [[ -z $mime ]] || xdg-mime default "$media_player" "$mime" || return
    done < <(sed -n 's/^MimeType=//p' "/usr/share/applications/$media_player" | tr ';' '\n')
  else
    warn "Celluloid desktop entry was not found"
  fi
  if [[ -n $papers ]]; then
    while IFS= read -r mime; do
      [[ -z $mime ]] || xdg-mime default "$papers" "$mime" || return
    done < <(sed -n 's/^MimeType=//p' "/usr/share/applications/$papers" | tr ';' '\n')
  else
    warn "Papers desktop entry was not found"
  fi
}

install_node_lts() {
  run_cmd mise use --global --yes node@lts
}

configure_local_postgres() {
  run_cmd podman pull docker.io/library/postgres:18 || return
  run_cmd systemctl --user restart postgres-local.service
}

finish_setup() {
  if ((${#FAILURES[@]})); then
    warn "Arch Hyprland setup finished with ${#FAILURES[@]} failure(s):"
    printf '  - %s\n' "${FAILURES[@]}" >&2
    return 1
  fi
  log "Arch Hyprland setup complete"
  info "Reboot to apply changes."
}

main() {
  local arg unit
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

  run_step "install missing official packages" install_official_packages
  run_step "install yay" ensure_yay
  run_step "install missing AUR packages" install_aur_packages
  run_step "install Mitishell (latest release)" install_mitishell
  run_step "configure mDNS" configure_mdns
  run_step "configure SSH keepalives" configure_ssh_keepalive
  run_step "configure UFW" configure_firewall
  run_step "configure systemd-oomd" configure_oomd
  run_step "configure Snapper and Limine" configure_snapper

  run_step "configure tty1 autologin" configure_autologin
  run_step "configure UWSM autostart in zprofile" configure_uwsm_autostart
  run_step "configure passwordless default keyring" configure_default_keyring

  if ! getent group i2c >/dev/null; then
    run_step "create i2c group" run_sudo groupadd --system i2c
  fi
  if ! id -nG "$USER" | tr ' ' '\n' | grep -qx i2c; then
    run_step "add $USER to i2c group" run_sudo usermod -aG i2c "$USER"
  fi
  if ! id -nG "$USER" | tr ' ' '\n' | grep -qx input; then
    run_step "add $USER to input group" run_sudo usermod -aG input "$USER"
  fi
  run_step "configure suspend lock workaround" configure_suspend_workaround
  for unit in NetworkManager.service avahi-daemon.service bluetooth.service cups.service \
    power-profiles-daemon.service systemd-timesyncd.service; do
    run_step "enable $unit" run_sudo systemctl enable "$unit"
  done
  for unit in paccache.timer btrfs-scrub@-.timer; do
    run_step "enable $unit" run_sudo systemctl enable --now "$unit"
  done
  run_step "mask NetworkManager-wait-online.service" run_sudo systemctl mask \
    NetworkManager-wait-online.service

  run_step "link configuration files" configure_dotfiles
  prompt_step "configure Voxtype dictation" configure_voxtype
  run_step "build Bat theme cache" run_cmd bat cache --build
  run_step "install Qt color scheme" ensure_root_file \
    /usr/share/qt6ct/colors/cinder-grove.conf \
    "$(<"$SCRIPT_DIR/qt6ct/colors/cinder-grove.conf")"$'\n'

  if [[ $(getent passwd "$USER" | cut -d: -f7) != /usr/bin/zsh ]]; then
    run_step "set Zsh as the login shell" run_sudo chsh -s /usr/bin/zsh "$USER"
  fi
  run_step "update XDG user directories" run_cmd xdg-user-dirs-update
  run_step "configure tmux-sessionizer" run_cmd tms config --paths "$HOME/Projects" "$HOME/Documents"

  run_step "reload user services" run_cmd systemctl --user daemon-reload
  run_step "configure local PostgreSQL" configure_local_postgres
  for unit in hypridle.service hyprsunset.service mitishell.service \
    home-backup.timer monitor-setup.service monitor-watch.service \
    udiskie.service hyprpaper.service hyprpolkitagent.service \
    pipewire-pulse.socket pipewire.socket podman.socket \
    wireplumber.service; do
    run_step "enable $unit" run_cmd systemctl --user enable "$unit"
  done
  prompt_step "install Cinder Grove GTK theme" install_gtk_theme
  run_step "configure desktop appearance" configure_gsettings
  prompt_step "install Cinder Grove Papirus folders" install_papirus_folders
  run_step "configure default applications" configure_default_apps
  run_step "configure Node.js LTS with mise" install_node_lts
  run_step "reload ddcutil rules" run_sudo udevadm control --reload-rules
  run_step "trigger ddcutil devices" run_sudo udevadm trigger --subsystem-match=i2c-dev
  if ((DRY_RUN)); then
    format_command ddcutil detect --brief
  elif ! ddcutil detect --brief; then
    warn "DDC/CI monitor control unavailable; enable it in each monitor OSD"
    fail "detect DDC/CI monitors"
  fi
  run_step "run postflight checks" run_cmd "$HOME/.local/bin/doctor"

  finish_setup
}

if [[ -z ${BASH_SOURCE[0]:-} || ${BASH_SOURCE[0]:-} == "$0" ]]; then
  main "$@"
fi
