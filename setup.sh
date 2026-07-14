#!/usr/bin/env bash
# shellcheck disable=SC2016

set -Eeuo pipefail

readonly DOTFILES_REPO="https://codeberg.org/aileks/dotfiles.git"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
readonly DOTFILES_DIR
SCRIPT_DIR=""
BACKUP_DIR="$HOME/.config-backup.$(date +%Y%m%d_%H%M%S)"
readonly BACKUP_DIR
BACKUP_SUFFIX=".backup.$(date +%Y%m%d_%H%M%S)"
readonly BACKUP_SUFFIX
readonly FLATHUB_URL="https://dl.flathub.org/repo/flathub.flatpakrepo"

DRY_RUN=0
ARCH=""
TEMP_DIR=""

readonly -a APT_PACKAGES=(
  7zip
  alacritty
  bat
  btop
  build-essential
  ca-certificates
  curl
  dconf-cli
  ddcutil
  eza
  fastfetch
  fd-find
  ffmpeg
  ffmpegthumbnailer
  flatpak
  fontconfig
  fwupd
  fzf
  git
  gnome-firmware
  gnome-shell-extension-manager
  gnome-shell-ubuntu-extensions
  gnome-software
  gnome-software-plugin-flatpak
  gnome-tweaks
  gpg
  i2c-tools
  jq
  less
  nautilus
  openssh-client
  papirus-icon-theme
  python3
  ripgrep
  shellcheck
  shfmt
  socat
  starship
  trash-cli
  unzip
  wget
  wl-clipboard
  xdg-terminal-exec
  xdg-utils
  xz-utils
  zoxide
  zsh
  zsh-antidote
)

readonly -a PACSTALL_PACKAGES=(
  neovim
  nerd-fonts-jetbrains-mono
  onlyoffice-desktopeditors-deb
  zen-browser-bin
)

readonly -a FLATPAK_APPS=(
  com.bitwarden.desktop
  com.fastmail.Fastmail
  org.localsend.localsend_app
)
readonly -a FLATPAK_THEMES=(
  org.gtk.Gtk3theme.adw-gtk3
  org.gtk.Gtk3theme.adw-gtk3-dark
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

run_apt() {
  if ((DRY_RUN)); then
    format_command sudo env DEBIAN_FRONTEND=noninteractive apt "$@"
    return 0
  fi
  sudo env DEBIAN_FRONTEND=noninteractive apt "$@"
}

has_tty() {
  [[ -r /dev/tty && -w /dev/tty ]] && (: </dev/tty) >/dev/null 2>&1
}

ensure_git() {
  command -v git >/dev/null && return 0

  info "installing Git for dotfiles bootstrap"
  run_apt update
  run_apt install -y ca-certificates git
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
  has_tty || die "move or remove $DOTFILES_DIR, then retry"

  printf 'Back up and replace it? [y/N] ' >/dev/tty
  IFS= read -r reply </dev/tty || reply=""
  [[ ${reply,,} == y || ${reply,,} == yes ]] || die "cancelled"
  run_cmd mv "$DOTFILES_DIR" "${DOTFILES_DIR}${BACKUP_SUFFIX}"
  log "backed up $DOTFILES_DIR to ${DOTFILES_DIR}${BACKUP_SUFFIX}"
}

update_dotfiles_repo() {
  local branch local_ref remote_ref
  if ((DRY_RUN)); then
    info "update existing dotfiles repository with a fast-forward merge"
    return 0
  fi

  info "updating existing dotfiles repository"
  if ! git -C "$DOTFILES_DIR" fetch origin; then
    warn "fetch failed; using local dotfiles checkout"
    return 0
  fi

  branch=$(git -C "$DOTFILES_DIR" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || true)
  branch=${branch#origin/}
  branch=${branch:-main}
  local_ref=$(git -C "$DOTFILES_DIR" rev-parse HEAD 2>/dev/null || true)
  remote_ref=$(git -C "$DOTFILES_DIR" rev-parse "origin/$branch" 2>/dev/null || true)

  if [[ -z $remote_ref ]]; then
    warn "origin/$branch is unavailable; using local dotfiles checkout"
  elif [[ $local_ref == "$remote_ref" ]]; then
    log "dotfiles already up to date"
  elif git -C "$DOTFILES_DIR" merge-base --is-ancestor HEAD "origin/$branch"; then
    git -C "$DOTFILES_DIR" merge --ff-only "origin/$branch" ||
      warn "fast-forward failed; using local dotfiles checkout"
  else
    warn "local dotfiles checkout is ahead or diverged; leaving it unchanged"
  fi
}

clone_dotfiles_repo() {
  local attempt
  info "cloning dotfiles repository"
  for attempt in {1..3}; do
    if run_cmd git clone "$DOTFILES_REPO" "$DOTFILES_DIR"; then
      log "cloned dotfiles repository"
      return 0
    fi
    warn "clone failed ($attempt/3)"
    ((attempt == 3)) || sleep 5
  done
  die "failed to clone dotfiles repository"
}

resolve_script_dir() {
  local self_path="${1:-}" self_dir=""
  if [[ -n $self_path && -f $self_path ]]; then
    self_dir=$(cd "$(dirname "$self_path")" && pwd)
  fi
  if [[ -n $self_dir && -d $self_dir/zsh ]]; then
    SCRIPT_DIR="$self_dir"
    readonly SCRIPT_DIR
    return 0
  fi

  ensure_git
  info "starting dotfiles bootstrap"
  if verify_dotfiles_repo; then
    update_dotfiles_repo
  elif [[ -e $DOTFILES_DIR || -L $DOTFILES_DIR ]]; then
    prompt_replace_repo
    clone_dotfiles_repo
  else
    clone_dotfiles_repo
  fi

  ((DRY_RUN)) || [[ -d $DOTFILES_DIR/zsh ]] ||
    die "dotfiles checkout is missing expected directory: $DOTFILES_DIR/zsh"
  SCRIPT_DIR="$DOTFILES_DIR"
  readonly SCRIPT_DIR
  log "using dotfiles from $SCRIPT_DIR"
}

validate_sha256() {
  [[ $1 =~ ^[[:xdigit:]]{64}$ ]]
}

dpkg_installed_version() {
  local result state version
  result=$(dpkg-query -W -f='${db:Status-Status}\t${Version}' "$1" 2>/dev/null) || return 1
  IFS=$'\t' read -r state version <<<"$result"
  [[ $state == installed ]] || return 1
  printf '%s\n' "$version"
}

verify_file() {
  local file="$1" expected="$2" actual
  validate_sha256 "$expected" || die "invalid SHA-256 digest for $(basename "$file")"
  actual=$(sha256sum "$file" | awk '{print $1}')
  [[ $actual == "$expected" ]] || die "checksum mismatch for $(basename "$file")"
}

fetch() {
  local url="$1" destination="$2"
  curl --proto '=https' --tlsv1.2 --fail --silent --show-error --location \
    --retry 3 --output "$destination" "$url"
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

read_os_release() {
  local os_release="${OS_RELEASE_FILE:-/etc/os-release}"
  [[ -r $os_release ]] || die "missing $os_release"
  # shellcheck disable=SC1090
  source "$os_release"
  [[ ${ID:-} == ubuntu && ${VERSION_ID:-} == 26.04 ]] ||
    die "Ubuntu 26.04 is required"
}

detect_architecture() {
  ARCH=$(dpkg --print-architecture)
  [[ $ARCH == amd64 ]] || die "this setup currently supports amd64 only (detected $ARCH)"
}

validate_user_id() {
  (($1 != 0)) || die "run as the desktop user, not root"
}

validate_environment() {
  read_os_release
  detect_architecture
  validate_user_id "$EUID"
  validate_desktop_session
}

validate_desktop_session() {
  [[ ${XDG_CURRENT_DESKTOP:-} =~ (GNOME|Ubuntu) ]] ||
    die "run from a logged-in Ubuntu GNOME session"
  [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]] ||
    die "a desktop D-Bus session is required"
  command -v gnome-shell >/dev/null || die "GNOME Shell is required"
}

create_temp_dir() {
  if ((DRY_RUN)); then
    TEMP_DIR="/tmp/dotfiles-setup-dry-run"
    return 0
  fi
  TEMP_DIR=$(mktemp -d)
  trap 'rm -rf "${TEMP_DIR:-}"' EXIT
}

local_user_homes() {
  local passwd_file="${PASSWD_FILE:-/etc/passwd}"
  awk -F: '($3 == 0 || ($3 >= 1000 && $3 < 65534)) && $6 ~ /^\// {print $6}' \
    "$passwd_file" | sort -u
}

user_snap_data_present() {
  local home
  while IFS= read -r home; do
    [[ -e $home/snap || -e $home/.snap ]] && return 0
  done < <(local_user_homes)
  return 1
}

snap_state_present() {
  command -v snap >/dev/null || dpkg_installed_version snapd >/dev/null ||
    [[ -e /var/lib/snapd || -e /var/snap ]] || user_snap_data_present
}

confirm_snap_purge() {
  ((DRY_RUN)) && return 0
  snap_state_present || return 0
  [[ -r /dev/tty && -w /dev/tty ]] ||
    die "Snap deletion requires an interactive terminal"

  local reply
  printf 'Permanently delete all Snap packages and data? [y/N] ' >/dev/tty
  IFS= read -r reply </dev/tty || reply=""
  [[ ${reply,,} == y || ${reply,,} == yes ]] || die "cancelled"
}

bootstrap_apt() {
  info "refreshing APT metadata"
  run_apt update
  run_apt install -y ca-certificates curl gpg jq
}

snap_names() {
  snap list 2>/dev/null | awk 'NR > 1 {print $1}'
}

remove_snap_packages() {
  command -v snap >/dev/null || return 0

  local attempt snap removed
  local -a snaps=()
  for ((attempt = 1; attempt <= 3; attempt++)); do
    mapfile -t snaps < <(snap_names | grep -v '^snapd$' || true)
    ((${#snaps[@]})) || break
    removed=0
    for snap in "${snaps[@]}"; do
      if run_sudo snap remove --purge "$snap"; then
        removed=1
      else
        warn "Snap removal deferred for dependency ordering: $snap"
      fi
    done
    ((removed)) || break
  done

  if snap_names | grep -qx snapd; then
    run_sudo snap remove --purge snapd || warn "snapd Snap could not be removed separately"
  fi
}

remove_user_snap_data() {
  local home
  local -a homes=()
  mapfile -t homes < <(local_user_homes)
  for home in "${homes[@]}"; do
    run_sudo rm -rf -- "$home/snap" "$home/.snap"
  done
}

purge_snap() {
  info "removing Snap"
  ensure_root_file /etc/apt/preferences.d/no-snap.pref $'Package: snapd\nPin: release a=*\nPin-Priority: -10\n'

  if ((DRY_RUN)); then
    info "remove every installed Snap with snap remove --purge"
  else
    remove_snap_packages
  fi

  run_sudo systemctl disable --now snapd.socket snapd.service snapd.seeded.service 2>/dev/null || true
  if ((DRY_RUN)); then
    info "unmount /var/snap if mounted"
  elif findmnt --mountpoint /var/snap >/dev/null; then
    run_sudo umount --recursive /var/snap
  fi
  run_apt purge -y snapd
  run_sudo rm -rf \
    /snap \
    /var/cache/snapd \
    /var/lib/snapd \
    /var/snap \
    /var/tmp/snap-private-tmp
  remove_user_snap_data
}

install_keyring() {
  local url="$1" path="$2"
  local armored binary
  armored="$TEMP_DIR/$(basename "$path").asc"
  binary="$TEMP_DIR/$(basename "$path")"
  if ((DRY_RUN)); then
    info "install signing key $path from $url"
    return 0
  fi
  fetch "$url" "$armored"
  gpg --batch --yes --dearmor --output "$binary" "$armored"
  if sudo test -f "$path" && sudo cmp --silent "$binary" "$path"; then
    return 0
  fi
  sudo install -D -o root -g root -m 0644 "$binary" "$path"
}

configure_vendor_repositories() {
  info "configuring Microsoft and Signal APT repositories"
  run_sudo rm -f /etc/apt/sources.list.d/vscode.list
  install_keyring \
    https://packages.microsoft.com/keys/microsoft.asc \
    /usr/share/keyrings/packages.microsoft.gpg
  ensure_root_file /etc/apt/sources.list.d/vscode.sources "Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: $ARCH
Signed-By: /usr/share/keyrings/packages.microsoft.gpg
"

  install_keyring \
    https://updates.signal.org/desktop/apt/keys.asc \
    /usr/share/keyrings/signal-desktop-keyring.gpg
  ensure_root_file /etc/apt/sources.list.d/signal-desktop.sources 'Types: deb
URIs: https://updates.signal.org/desktop/apt
Suites: xenial
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/signal-desktop-keyring.gpg
'
}

install_apt_software() {
  info "installing Ubuntu and vendor APT packages"
  run_apt update
  run_apt purge -y gnome-shell-extension-prefs
  run_apt install -y "${APT_PACKAGES[@]}" code signal-desktop
}

install_uv() {
  if [[ -x $HOME/.local/bin/uv ]]; then
    log "$("$HOME/.local/bin/uv" --version) already installed"
    return 0
  fi
  if ((DRY_RUN)); then
    info "install uv with the official Astral installer"
    format_command bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
    return 0
  fi

  curl -LsSf https://astral.sh/uv/install.sh | sh
  "$HOME/.local/bin/uv" --version >/dev/null || die "uv installation failed"
}

installed_nvm_version() {
  [[ -s $HOME/.nvm/nvm.sh ]] || return 1
  env NVM_DIR="$HOME/.nvm" bash -c '. "$NVM_DIR/nvm.sh"; nvm --version'
}

latest_nvm_version() {
  local json="$TEMP_DIR/nvm-release.json" tag
  fetch https://api.github.com/repos/nvm-sh/nvm/releases/latest "$json"
  release_is_stable "$json" || die "latest NVM release is not stable"
  tag=$(jq -r '.tag_name' "$json")
  [[ $tag =~ ^v[0-9]+[.][0-9]+[.][0-9]+$ ]] || die "latest NVM release has an invalid tag"
  printf '%s\n' "${tag#v}"
}

install_nvm() {
  local installed version
  if ((DRY_RUN)); then
    info "resolve and install the latest stable NVM release"
    return 0
  fi

  version=$(latest_nvm_version)
  installed=$(installed_nvm_version 2>/dev/null || true)
  if [[ $installed == "$version" ]]; then
    log "NVM $version already installed"
    return 0
  fi

  curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v$version/install.sh" | bash
  installed=$(installed_nvm_version 2>/dev/null || true)
  [[ $installed == "$version" ]] || die "NVM $version installation failed"
}

install_node_lts() {
  if ((DRY_RUN)); then
    info "install current Node.js LTS and bundled npm with NVM"
    format_command bash -c '. "$NVM_DIR/nvm.sh"; nvm install --lts; nvm alias default "lts/*"'
    return 0
  fi

  [[ -s $HOME/.nvm/nvm.sh ]] || die "NVM is required before installing Node.js"
  env NVM_DIR="$HOME/.nvm" bash -c '
    set -e
    . "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm alias default "lts/*"
    nvm use default > /dev/null
    node --version
    npm --version
  '
}

install_pnpm() {
  if ((DRY_RUN)); then
    info "install pnpm globally with npm"
    format_command bash -c '. "$NVM_DIR/nvm.sh"; nvm use default; npm install --global pnpm'
    return 0
  fi

  env NVM_DIR="$HOME/.nvm" bash -c '
    set -e
    . "$NVM_DIR/nvm.sh"
    nvm use default > /dev/null
    npm install --global pnpm
    pnpm --version
  '
}

install_developer_tools() {
  info "installing developer runtimes and package managers"
  install_uv
  install_nvm
  install_node_lts
  install_pnpm
}

release_is_stable() {
  local json="$1"
  jq -e '.draft == false and .prerelease == false and (.tag_name | type == "string")' \
    "$json" >/dev/null
}

select_release_asset() {
  local json="$1" pattern="$2" label="$3" asset name url digest
  local -a assets=()
  release_is_stable "$json" || die "$label latest release is not stable"
  mapfile -t assets < <(
    jq -r --arg pattern "$pattern" '.assets[] | select(.name | test($pattern)) |
      [.name, .browser_download_url, .digest] | @tsv' "$json"
  )
  ((${#assets[@]} == 1)) || die "expected one $label release asset"
  asset=${assets[0]}
  IFS=$'\t' read -r name url digest <<<"$asset"
  digest=${digest#sha256:}
  [[ $url == https://* ]] || die "$label release asset has an invalid URL"
  validate_sha256 "$digest" || die "$label release asset has no valid digest"
  printf '%s\t%s\t%s\n' "$name" "$url" "$digest"
}

install_pacstall() {
  if command -v pacstall >/dev/null; then
    log "Pacstall already installed"
    return 0
  fi

  if ((DRY_RUN)); then
    printf '  $ sudo bash -c "$(curl -fsSL https://pacstall.dev/q/install)"\n'
    return 0
  fi

  sudo bash -c "$(curl -fsSL https://pacstall.dev/q/install)"
  command -v pacstall >/dev/null || die "Pacstall installation failed"
}

install_pacstall_packages() {
  local package output
  local -a installed=()

  if command -v pacstall >/dev/null; then
    output=$(pacstall -L 2>/dev/null) || die "could not list installed Pacstall packages"
    mapfile -t installed <<<"$output"
  elif ((!DRY_RUN)); then
    die "Pacstall is unavailable"
  fi

  info "installing Pacstall packages"
  for package in "${PACSTALL_PACKAGES[@]}"; do
    if array_contains "$package" "${installed[@]}"; then
      log "$package already installed"
      continue
    fi
    run_cmd pacstall -P -I "$package"
    installed+=("$package")
  done
}

configure_default_browser() {
  local selected
  info "setting Zen Browser as the default browser"
  run_cmd xdg-settings set default-web-browser zen-browser.desktop

  ((DRY_RUN)) && return 0
  selected=$(xdg-settings get default-web-browser)
  [[ $selected == zen-browser.desktop ]] ||
    die "default browser is $selected; expected zen-browser.desktop"
}

nerd_fonts_release() {
  local json="$1"
  fetch https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest "$json"
  release_is_stable "$json" || die "Nerd Fonts latest release is not stable"
}

prepare_font_directory() {
  local path="$1"
  [[ -e $path || -L $path ]] || return 0
  if [[ -f $path/.version ]]; then
    rm -rf "$path"
  else
    backup_target "$path"
  fi
}

install_archive_font() {
  local release_json="$1" asset_name="$2" family_dir="$3" version="$4"
  local font_dir="$HOME/.local/share/fonts/$family_dir"
  local checksums_url asset_url checksum archive checksums extract_dir

  if [[ -f $font_dir/.version ]] && [[ $(<"$font_dir/.version") == "$version" ]]; then
    log "$family_dir $version already installed"
    return 0
  fi

  checksums_url=$(jq -r '.assets[] | select(.name == "SHA-256.txt") | .browser_download_url' "$release_json")
  asset_url=$(jq -r --arg name "$asset_name" \
    '.assets[] | select(.name == $name) | .browser_download_url' "$release_json")
  [[ -n $checksums_url && $checksums_url != null ]] || die "Nerd Fonts checksum asset missing"
  [[ -n $asset_url && $asset_url != null ]] || die "Nerd Fonts asset missing: $asset_name"

  checksums="$TEMP_DIR/nerd-fonts-SHA-256.txt"
  archive="$TEMP_DIR/$asset_name"
  extract_dir="$TEMP_DIR/${family_dir}-extract"
  fetch "$checksums_url" "$checksums"
  checksum=$(awk -v name="$asset_name" '$2 == name {print $1}' "$checksums")
  validate_sha256 "$checksum" || die "invalid Nerd Fonts checksum for $asset_name"
  fetch "$asset_url" "$archive"
  verify_file "$archive" "$checksum"

  rm -rf "$extract_dir"
  mkdir -p "$extract_dir"
  tar -xJf "$archive" -C "$extract_dir"
  prepare_font_directory "$font_dir"
  mkdir -p "$font_dir"
  find "$extract_dir" -type f \( -name '*.ttf' -o -name '*.otf' \) -exec cp -f {} "$font_dir/" \;
  printf '%s\n' "$version" >"$font_dir/.version"
}

install_fonts() {
  if ((DRY_RUN)); then
    info "install verified AdwaitaMono.tar.xz per-user"
    format_command fc-cache -f "$HOME/.local/share/fonts"
    return 0
  fi

  local release_json="$TEMP_DIR/nerd-fonts-release.json"
  local latest_version
  nerd_fonts_release "$release_json"
  latest_version=$(jq -r '.tag_name | ltrimstr("v")' "$release_json")

  prepare_font_directory "$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
  install_archive_font "$release_json" AdwaitaMono.tar.xz AdwaitaMonoNerdFont "$latest_version"
  run_cmd fc-cache -f "$HOME/.local/share/fonts"
}

install_flatpaks() {
  info "installing user-scoped Flatpaks"
  verify_flathub_remote
  run_cmd flatpak remote-add --user --if-not-exists flathub "$FLATHUB_URL"
  run_cmd flatpak install --user --noninteractive -y flathub "${FLATPAK_APPS[@]}"
  run_cmd flatpak install --user --noninteractive -y flathub "${FLATPAK_THEMES[@]}"
  run_cmd flatpak override --user --filesystem=xdg-config/gtk-3.0 \
    --filesystem=xdg-config/gtk-4.0
}

verify_flathub_remote() {
  ((DRY_RUN)) && return 0
  local url
  url=$(flatpak remotes --user --columns=name,url |
    awk -F '\t' '$1 == "flathub" {print $2; exit}')
  [[ -z $url ]] && return 0
  case "${url%/}" in
    https://dl.flathub.org/repo | https://flathub.org/repo) ;;
    *) die "existing user flathub remote points to an unexpected URL: $url" ;;
  esac
}

install_adw_gtk3() {
  info "installing adw-gtk3 system-wide"
  if ((DRY_RUN)); then
    info "resolve latest stable adw-gtk3 archive, verify GitHub digest, install to /usr/share/themes"
    return 0
  fi

  local json="$TEMP_DIR/adw-gtk3-release.json"
  local tag name url digest archive extract_dir version_file light_installed dark_installed asset
  local light_dir dark_dir
  fetch https://api.github.com/repos/lassekongo83/adw-gtk3/releases/latest "$json"
  tag=$(jq -r '.tag_name' "$json")
  asset=$(select_release_asset "$json" '^adw-gtk3v.+[.]tar[.]xz$' 'adw-gtk3 theme archive')
  IFS=$'\t' read -r name url digest <<<"$asset"

  light_installed=$(sudo cat /usr/share/themes/adw-gtk3/.version 2>/dev/null || true)
  dark_installed=$(sudo cat /usr/share/themes/adw-gtk3-dark/.version 2>/dev/null || true)
  if [[ $light_installed == "$tag" && $dark_installed == "$tag" ]]; then
    log "adw-gtk3 $tag already installed"
    return 0
  fi

  archive="$TEMP_DIR/$name"
  extract_dir="$TEMP_DIR/adw-gtk3-extract"
  fetch "$url" "$archive"
  verify_file "$archive" "$digest"
  mkdir -p "$extract_dir"
  tar -xJf "$archive" -C "$extract_dir"

  light_dir="$extract_dir/adw-gtk3"
  dark_dir="$extract_dir/adw-gtk3-dark"
  [[ -f $light_dir/index.theme && -f $dark_dir/index.theme ]] ||
    die "adw-gtk3 archive is missing theme metadata"

  run_sudo install -d -m 0755 /usr/share/themes
  run_sudo cp -a "$light_dir" "$dark_dir" /usr/share/themes/
  version_file="$TEMP_DIR/adw-gtk3.version"
  printf '%s\n' "$tag" >"$version_file"
  run_sudo install -m 0644 "$version_file" /usr/share/themes/adw-gtk3/.version
  run_sudo install -m 0644 "$version_file" /usr/share/themes/adw-gtk3-dark/.version
}

array_contains() {
  local needle="$1" item
  shift
  for item in "$@"; do
    [[ $item == "$needle" ]] && return 0
  done
  return 1
}

gvariant_array() {
  local item escaped separator="" output="["
  for item in "$@"; do
    escaped=${item//\'/\\\'}
    output+="$separator'$escaped'"
    separator=", "
  done
  printf '%s]\n' "$output"
}

read_gsettings_array() {
  gsettings get "$1" "$2" | python3 -c '
import ast
import sys

raw = sys.stdin.read().strip()
if raw.startswith("@as "):
    raw = raw[4:]
for value in ast.literal_eval(raw):
    print(value)
'
}

gs_set() {
  run_cmd gsettings set "$@"
}

configure_workspace_shortcuts() {
  local workspace
  for workspace in {1..7}; do
    gs_set org.gnome.desktop.wm.keybindings "switch-to-workspace-$workspace" \
      "['<Super>$workspace']"
    gs_set org.gnome.desktop.wm.keybindings "move-to-workspace-$workspace" \
      "['<Super><Shift>$workspace']"
    gs_set org.gnome.shell.keybindings "switch-to-application-$workspace" '[]'
  done
}

set_custom_shortcut() {
  local path="$1" name="$2" command="$3" binding="$4"
  local schema="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path"
  gs_set "$schema" name "$name"
  gs_set "$schema" command "$command"
  gs_set "$schema" binding "$binding"
}

configure_custom_shortcuts() {
  local base="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
  local legacy_browser="$base/dotfiles-browser/"
  local legacy_home="$base/dotfiles-home/"
  local brightness_down="$base/dotfiles-brightness-down/"
  local brightness_up="$base/dotfiles-brightness-up/"
  local signal="$base/dotfiles-signal/"
  local fastmail="$base/dotfiles-fastmail/"
  local -a managed=(
    "$brightness_down"
    "$brightness_up"
    "$signal"
    "$fastmail"
  )

  if ((DRY_RUN)); then
    info "remove legacy Home and browser custom shortcuts; preserve unrelated shortcuts"
  else
    local path
    local -a existing=() merged=()
    mapfile -t existing < <(
      read_gsettings_array org.gnome.settings-daemon.plugins.media-keys custom-keybindings
    )
    for path in "${existing[@]}"; do
      [[ $path == "$legacy_browser" || $path == "$legacy_home" ]] && continue
      array_contains "$path" "${merged[@]}" || merged+=("$path")
    done
    for path in "${managed[@]}"; do
      array_contains "$path" "${merged[@]}" || merged+=("$path")
    done
    gs_set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
      "$(gvariant_array "${merged[@]}")"
  fi

  set_custom_shortcut "$brightness_down" "Brightness down" \
    "$HOME/.local/bin/monitor-brightness down" 'XF86MonBrightnessDown'
  set_custom_shortcut "$brightness_up" "Brightness up" \
    "$HOME/.local/bin/monitor-brightness up" 'XF86MonBrightnessUp'
  set_custom_shortcut "$signal" Signal signal-desktop '<Super>s'
  set_custom_shortcut "$fastmail" Fastmail \
    'flatpak run com.fastmail.Fastmail' '<Super>m'
}

configure_shortcut_preferences() {
  local media="org.gnome.settings-daemon.plugins.media-keys"
  local shell="org.gnome.shell.keybindings"
  local wm="org.gnome.desktop.wm.keybindings"

  gs_set "$media" control-center "['<Super>i']"
  gs_set "$media" home "['<Super>e']"
  gs_set "$media" screensaver "['<Alt><Super>l']"
  gs_set "$media" search "['<Alt>F2']"
  gs_set "$media" terminal "['<Super>Return']"
  gs_set "$media" www "['<Super>w']"
  gs_set "$shell" toggle-message-tray "['<Super>v']"
  gs_set "$shell" toggle-overview "['<Super>space']"
  gs_set "$shell" toggle-quick-settings '[]'
  gs_set "$shell" screen-brightness-down '[]'
  gs_set "$shell" screen-brightness-up '[]'
  gs_set "$wm" close "['<Super>q']"
  gs_set "$wm" minimize '[]'
  gs_set "$wm" panel-run-dialog '[]'
  gs_set "$wm" switch-input-source '[]'
  gs_set "$wm" switch-input-source-backward '[]'
  gs_set org.gnome.mutter.wayland.keybindings restore-shortcuts '[]'
}

verify_gsetting() {
  ((DRY_RUN)) && return 0
  local schema="$1" key="$2" expected="$3" actual
  actual=$(gsettings get "$schema" "$key")
  [[ $actual == "$expected" ]] ||
    die "$schema $key is $actual; expected $expected"
}

verify_dconf_value() {
  ((DRY_RUN)) && return 0
  local path="$1" expected="$2" actual
  actual=$(dconf read "$path")
  [[ $actual == "$expected" ]] ||
    die "$path is $actual; expected $expected"
}

configure_gnome() {
  info "configuring GNOME"
  gs_set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
  gs_set org.gnome.desktop.interface icon-theme Papirus-Dark
  gs_set org.gnome.desktop.interface color-scheme prefer-dark
  run_cmd dconf write /org/gnome/desktop/interface/accent-color "'#B34A45'"
  gs_set org.gnome.desktop.peripherals.keyboard repeat true
  gs_set org.gnome.desktop.peripherals.keyboard delay 245
  gs_set org.gnome.desktop.peripherals.keyboard repeat-interval 20
  gs_set org.gnome.desktop.input-sources xkb-options "['ctrl:swapcaps']"
  gs_set org.gnome.desktop.peripherals.mouse accel-profile flat
  gs_set org.gnome.mutter dynamic-workspaces false
  gs_set org.gnome.desktop.wm.preferences num-workspaces 7
  gs_set org.gnome.desktop.wm.preferences mouse-button-modifier '<Super>'
  gs_set org.gnome.desktop.wm.preferences resize-with-right-button true
  configure_workspace_shortcuts
  configure_shortcut_preferences
  configure_custom_shortcuts

  verify_gsetting org.gnome.desktop.interface gtk-theme "'adw-gtk3-dark'"
  verify_gsetting org.gnome.desktop.interface icon-theme "'Papirus-Dark'"
  verify_gsetting org.gnome.desktop.interface color-scheme "'prefer-dark'"
  verify_dconf_value /org/gnome/desktop/interface/accent-color "'#B34A45'"
  verify_gsetting org.gnome.desktop.peripherals.keyboard repeat true
  verify_gsetting org.gnome.desktop.peripherals.keyboard delay 'uint32 245'
  verify_gsetting org.gnome.desktop.peripherals.keyboard repeat-interval 'uint32 20'
  verify_gsetting org.gnome.desktop.peripherals.mouse accel-profile "'flat'"
}

configure_default_terminal() {
  info "setting Alacritty as the default terminal"
  local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  local config="$config_home/ubuntu-xdg-terminals.list"
  local tmp="$TEMP_DIR/ubuntu-xdg-terminals.list" selected alternative

  run_sudo update-alternatives --set x-terminal-emulator /usr/bin/alacritty
  gs_set org.gnome.desktop.default-applications.terminal exec xdg-terminal-exec
  gs_set org.gnome.desktop.default-applications.terminal exec-arg --

  if ((DRY_RUN)); then
    info "put Alacritty first in $config"
    return 0
  fi

  mkdir -p "$config_home"
  {
    printf 'Alacritty.desktop\n'
    [[ ! -f $config ]] || awk '$0 != "Alacritty.desktop"' "$config"
  } >"$tmp"
  if [[ ! -f $config ]] || ! cmp --silent "$tmp" "$config"; then
    install -m 0644 "$tmp" "$config"
  fi

  verify_gsetting org.gnome.desktop.default-applications.terminal exec "'xdg-terminal-exec'"
  verify_gsetting org.gnome.desktop.default-applications.terminal exec-arg "'--'"
  selected=$(xdg-terminal-exec --print-id)
  [[ $selected == Alacritty.desktop ]] ||
    die "xdg-terminal-exec selected $selected instead of Alacritty.desktop"
  alternative=$(update-alternatives --query x-terminal-emulator |
    awk '$1 == "Value:" {print $2}')
  [[ $alternative == /usr/bin/alacritty ]] ||
    die "x-terminal-emulator selected $alternative instead of /usr/bin/alacritty"
}

backup_target() {
  local target="$1"
  local backup
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

configure_dotfiles() {
  info "linking Cinder Grove dotfiles"
  link_path "$SCRIPT_DIR/alacritty" "$HOME/.config/alacritty"
  link_path "$SCRIPT_DIR/bat" "$HOME/.config/bat"
  link_path "$SCRIPT_DIR/btop" "$HOME/.config/btop"
  link_path "$SCRIPT_DIR/fastfetch" "$HOME/.config/fastfetch"
  link_path "$SCRIPT_DIR/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"
  link_path "$SCRIPT_DIR/nvim" "$HOME/.config/nvim"
  link_path "$SCRIPT_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
  link_path "$SCRIPT_DIR/zsh/zshrc" "$HOME/.zshrc"

  link_path /usr/bin/batcat "$HOME/.local/bin/bat"
  link_path /usr/bin/fdfind "$HOME/.local/bin/fd"
  link_path "$SCRIPT_DIR/bin/monitor-brightness" "$HOME/.local/bin/monitor-brightness"

  local current_shell
  current_shell=$(getent passwd "$USER" | cut -d: -f7)
  if [[ $current_shell != /usr/bin/zsh ]]; then
    run_sudo chsh -s /usr/bin/zsh "$USER"
  fi
}

configure_ddcutil() {
  info "reloading ddcutil device permissions"
  run_sudo udevadm control --reload-rules
  run_sudo udevadm trigger --subsystem-match=i2c-dev || warn "could not trigger i2c-dev udev rules"

  if ((DRY_RUN)); then
    format_command ddcutil detect
    format_command ddcutil getvcp 10
    return 0
  fi

  if ddcutil detect; then
    ddcutil getvcp 10 || warn "monitors detected, but brightness VCP 10 was unavailable"
  else
    warn "ddcutil found no controllable monitor; enable DDC/CI in each external monitor's OSD"
  fi
}

main() {
  parse_args "$@"
  validate_environment
  create_temp_dir
  resolve_script_dir "${BASH_SOURCE[0]:-}"
  confirm_snap_purge
  ((DRY_RUN)) || sudo -v

  bootstrap_apt
  purge_snap
  configure_vendor_repositories
  install_apt_software
  install_developer_tools
  install_pacstall
  install_pacstall_packages
  configure_default_browser
  install_fonts
  install_flatpaks
  install_adw_gtk3
  configure_default_terminal
  configure_gnome
  configure_dotfiles
  configure_ddcutil

  log "setup complete"
  info "Reboot to apply changes!"
}

if [[ -z ${BASH_SOURCE[0]:-} || ${BASH_SOURCE[0]:-} == "$0" ]]; then
  main "$@"
fi
