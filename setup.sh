#!/usr/bin/env bash

# Omarchy post-install: personal apps, config links, and personal system bits.
# Never writes to /usr/share/omarchy or replaces Omarchy defaults.

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
  7zip alacritty alsa-utils avahi base-devel bat bitwarden bluez bluez-utils btop
  cava celluloid cups curl ddcutil eza fastfetch fd ffmpeg ffmpegthumbnailer file-roller
  fontconfig fzf gedit gnome-disk-utility gnome-keyring localsend libva-nvidia-driver libva-utils
  gvfs gvfs-afc gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-smb hunspell-en_us imv inotify-tools jq
  lazygit less libnotify lua man-db mesa-utils nautilus networkmanager nss-mdns nvm
  openssh pavucontrol playerctl python
  ripgrep rsync satty shellcheck signal-desktop starship system-config-printer tesseract
  tesseract-data-eng tmux trash-cli udiskie udisks2 unzip uv vulkan-tools wev wget
  wl-clipboard xdg-user-dirs xdg-utils xorg-xwayland zip zoxide zsh adwaita-fonts
  papirus-icon-theme ttf-adwaitamono-nerd otf-latin-modern otf-latinmodern-math
)

readonly -a AUR_PACKAGES=(
  fastmail tmux-sessionizer-bin
  zen-browser-twilight-bin zsh-antidote
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

has_tty() {
  [[ -r /dev/tty && -w /dev/tty ]] && (: </dev/tty) >/dev/null 2>&1
}

validate_environment() {
  local distro_id distro_like os_release="${OS_RELEASE_FILE:-/etc/os-release}"
  [[ -r $os_release ]] || die "missing $os_release"
  # shellcheck disable=SC1090
  source "$os_release"
  distro_id=${ID:-unknown}
  distro_like=${ID_LIKE:-}
  # Omarchy identifies as ID=omarchy, ID_LIKE=arch.
  [[ $distro_id == arch || $distro_like == *arch* ]] ||
    die "Arch Linux (or an Arch-based distro like Omarchy) is required"
  ((EUID != 0)) || die "run as the desktop user, not root"
  command -v sudo >/dev/null || die "sudo is required"
  getent passwd "$USER" >/dev/null || die "could not resolve user $USER"
  [[ $(uname -m) == x86_64 ]] || die "x86_64 is required"
  [[ -d /run/systemd/system ]] || die "systemd must be running"
  command -v omarchy >/dev/null ||
    die "Omarchy is required; this script is an Omarchy post-install"
  [[ -d ${OMARCHY_PATH:-/usr/share/omarchy} ]] ||
    die "Omarchy installation not found at ${OMARCHY_PATH:-/usr/share/omarchy}"
  command -v yay >/dev/null ||
    die "yay is required (Omarchy's package helper)"
}

ensure_git() {
  command -v git >/dev/null && return 0
  info "installing git for bootstrap..."
  run_cmd yay -S --needed --noconfirm git base-devel || die "Git installation failed"
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

install_packages() {
  local -a missing=()
  local package

  mapfile -t missing < <(missing_packages "${PACMAN_PACKAGES[@]}" "${AUR_PACKAGES[@]}")
  if ((${#missing[@]} == 0)); then
    log "all packages are already installed"
    return 0
  fi
  info "installing ${#missing[@]} missing packages with yay..."
  if run_cmd yay -S --needed --noconfirm "${missing[@]}"; then
    return 0
  fi
  # One conflict aborts the whole batch; retry per package.
  warn "batch install failed; retrying package by package..."
  for package in "${missing[@]}"; do
    run_cmd yay -S --needed --noconfirm "$package" ||
      fail "install package $package"
  done
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
  run_sudo cp "$path" "/var/backups/aileks-dotfiles-nsswitch.conf" 2>/dev/null || true
  ensure_root_file "$path" "$updated"$'\n'
}

configure_dotfiles() {
  local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  info "linking configuration files..."
  link_path "$SCRIPT_DIR/git/.gitconfig" "$HOME/.gitconfig"
  link_path "$SCRIPT_DIR/git/.gitignore_global" "$HOME/.gitignore_global"
  link_path "$SCRIPT_DIR/alacritty" "$config_home/alacritty"
  link_path "$SCRIPT_DIR/bat" "$config_home/bat"
  link_path "$SCRIPT_DIR/btop" "$config_home/btop"
  link_path "$SCRIPT_DIR/cava" "$config_home/cava"
  link_path "$SCRIPT_DIR/fastfetch" "$config_home/fastfetch"
  link_path "$SCRIPT_DIR/hypr" "$config_home/hypr"
  link_path "$SCRIPT_DIR/nvim" "$config_home/nvim"
  link_path "$SCRIPT_DIR/tmux" "$config_home/tmux"
  link_path "$SCRIPT_DIR/uwsm" "$config_home/uwsm"
  link_path "$SCRIPT_DIR/zsh/zshrc" "$HOME/.zshrc"
  link_path "$SCRIPT_DIR/starship/starship.toml" "$config_home/starship.toml"

  # Linked individually: Omarchy owns the rest of ~/.config/omarchy.
  link_path "$SCRIPT_DIR/omarchy/shell.toml" "$config_home/omarchy/shell.toml"
  link_path "$SCRIPT_DIR/omarchy/shell.json" "$config_home/omarchy/shell.json"
  link_path "$SCRIPT_DIR/omarchy/themes/cinder-grove" \
    "$config_home/omarchy/themes/cinder-grove"
  link_path "$SCRIPT_DIR/omarchy/hooks/theme-set.d/cinder-grove-gtk.hook" \
    "$config_home/omarchy/hooks/theme-set.d/cinder-grove-gtk.hook"
  link_path "$SCRIPT_DIR/omarchy/hooks/post-boot.d/01-pin-bar-font" \
    "$config_home/omarchy/hooks/post-boot.d/01-pin-bar-font"

  run_cmd mkdir -p "$config_home/systemd/user" || return
  for config in "$SCRIPT_DIR"/systemd/user/*.service; do
    unit=$(basename "$config")
    link_path "$config" "$config_home/systemd/user/$unit"
  done

  for script in "$SCRIPT_DIR"/bin/*; do
    link_path "$script" "$HOME/.local/bin/$(basename "$script")"
  done
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

configure_default_apps() {
  local browser terminal editor image_viewer media_player mime
  ((DRY_RUN)) && return 0

  browser=$(desktop_id zen-browser-twilight.desktop zen.desktop zen-browser.desktop || true)
  terminal=$(desktop_id Alacritty.desktop alacritty.desktop || true)
  editor=$(desktop_id org.gnome.gedit.desktop gedit.desktop || true)
  image_viewer=$(desktop_id imv.desktop || true)
  media_player=$(desktop_id io.github.celluloid_player.Celluloid.desktop || true)

  if [[ -n $browser ]]; then
    xdg-settings set default-web-browser "$browser" || return
    xdg-mime default "$browser" x-scheme-handler/http || return
    xdg-mime default "$browser" x-scheme-handler/https || return
    xdg-mime default "$browser" text/html || return
  else
    warn "Zen Browser desktop entry was not found"
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
}

install_node_lts() {
  local default_version lts_version
  [[ -r /usr/share/nvm/init-nvm.sh ]] || {
    warn "nvm is not installed; skipping Node.js setup"
    return 0
  }
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
  if ((DRY_RUN)); then
    TEMP_DIR=/tmp/setup-dry-run
  else
    TEMP_DIR=$(mktemp -d) || die "could not create a temporary directory"
    trap 'rm -rf "${TEMP_DIR:-}"' EXIT
  fi
  resolve_script_dir "${BASH_SOURCE[0]:-}"
  ((DRY_RUN)) || sudo -v || die "sudo authentication failed"

  run_step "install missing packages" install_packages
  run_step "configure mDNS" configure_mdns

  if ! getent group i2c >/dev/null; then
    run_step "create i2c group" run_sudo groupadd --system i2c
  fi
  if ! id -nG "$USER" | tr ' ' '\n' | grep -qx i2c; then
    run_step "add $USER to i2c group" run_sudo usermod -aG i2c "$USER"
  fi

  for unit in NetworkManager.service avahi-daemon.service bluetooth.service cups.service \
    systemd-timesyncd.service; do
    run_step "enable $unit" run_sudo systemctl enable "$unit"
  done

  run_step "link configuration files" configure_dotfiles
  run_step "build Bat theme cache" run_cmd bat cache --build

  if [[ $(getent passwd "$USER" | cut -d: -f7) != /usr/bin/zsh ]]; then
    run_step "set Zsh as the login shell" run_sudo chsh -s /usr/bin/zsh "$USER"
  fi
  run_step "update XDG user directories" run_cmd xdg-user-dirs-update
  run_step "configure tmux-sessionizer" run_cmd tms config --paths "$HOME/Projects"

  run_step "reload user services" run_cmd systemctl --user daemon-reload
  run_step "enable and start udiskie.service" run_cmd systemctl --user enable --now \
    udiskie.service

  run_step "configure default applications" configure_default_apps
  run_step "install Cinder Grove Papirus folders" install_papirus_folders
  run_step "configure Papirus folders" run_cmd papirus-folders-cg --color orange \
    --theme Papirus-Dark
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
    warn "Omarchy post-install finished with ${#FAILURES[@]} failure(s):"
    printf '  - %s\n' "${FAILURES[@]}" >&2
  else
    log "Omarchy post-install complete"
    info "Reboot if this was a fresh install; otherwise enjoy!"
  fi
  return 0
}

if [[ -z ${BASH_SOURCE[0]:-} || ${BASH_SOURCE[0]:-} == "$0" ]]; then
  main "$@"
fi
