#!/usr/bin/env bash

set -Eeuo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TEST_DIR
ROOT_DIR="$(cd "$TEST_DIR/.." && pwd)"
readonly ROOT_DIR
SETUP="$ROOT_DIR/setup.sh"
readonly SETUP

tests_run=0

fail() {
  printf 'not ok %d - %s\n' "$tests_run" "$*" >&2
  exit 1
}

pass() {
  printf 'ok %d - %s\n' "$tests_run" "$1"
}

assert_eq() {
  local expected="$1" actual="$2" message="$3"
  [[ $actual == "$expected" ]] || {
    printf 'expected:\n%s\nactual:\n%s\n' "$expected" "$actual" >&2
    fail "$message"
  }
}

assert_contains() {
  local haystack="$1" needle="$2" message="$3"
  [[ $haystack == *"$needle"* ]] || fail "$message: missing $needle"
}

assert_not_contains() {
  local haystack="$1" needle="$2" message="$3"
  [[ $haystack != *"$needle"* ]] || fail "$message: unexpectedly contained $needle"
}

run_test() {
  local name="$1"
  shift
  ((tests_run += 1))
  "$@"
  pass "$name"
}

test_parse_args() {
  local output

  output=$(bash -c 'source "$1"; parse_args --dry-run; printf "%s" "$DRY_RUN"' _ "$SETUP")
  assert_eq 1 "$output" '--dry-run was not accepted'

  if output=$(bash -c 'source "$1"; parse_args --help' _ "$SETUP" 2>&1); then
    fail 'unsupported option was accepted'
  fi
  assert_contains "$output" 'unknown option: --help' 'unsupported option error'

  if output=$(bash -c 'source "$1"; parse_args positional' _ "$SETUP" 2>&1); then
    fail 'positional argument was accepted'
  fi
  assert_contains "$output" 'unknown option: positional' 'positional argument error'
}

test_os_guard() {
  local tmp output
  tmp=$(mktemp -d)
  printf 'ID=ubuntu\nVERSION_ID=26.04\n' > "$tmp/valid"
  printf 'ID=ubuntu\nVERSION_ID=24.04\n' > "$tmp/wrong-version"
  printf 'ID=debian\nVERSION_ID=26.04\n' > "$tmp/wrong-id"

  OS_RELEASE_FILE="$tmp/valid" bash -c 'source "$1"; read_os_release' _ "$SETUP"

  if output=$(OS_RELEASE_FILE="$tmp/wrong-version" bash -c \
    'source "$1"; read_os_release' _ "$SETUP" 2>&1); then
    rm -rf "$tmp"
    fail 'wrong Ubuntu version passed OS guard'
  fi
  assert_contains "$output" 'Ubuntu 26.04 is required' 'wrong version error'

  if output=$(OS_RELEASE_FILE="$tmp/wrong-id" bash -c \
    'source "$1"; read_os_release' _ "$SETUP" 2>&1); then
    rm -rf "$tmp"
    fail 'non-Ubuntu OS passed OS guard'
  fi
  assert_contains "$output" 'Ubuntu 26.04 is required' 'wrong OS error'
  rm -rf "$tmp"
}

test_desktop_session_guard() {
  local output
  if output=$(XDG_CURRENT_DESKTOP=KDE DBUS_SESSION_BUS_ADDRESS=session bash -c '
    source "$1"
    gnome-shell() { printf "GNOME Shell 50.1\n"; }
    validate_desktop_session
  ' _ "$SETUP" 2>&1); then
    fail 'non-GNOME desktop passed session guard'
  fi
  assert_contains "$output" 'logged-in Ubuntu GNOME session' 'desktop session error'

  if output=$(XDG_CURRENT_DESKTOP=ubuntu:GNOME DBUS_SESSION_BUS_ADDRESS='' bash -c '
    source "$1"
    gnome-shell() { printf "GNOME Shell 50.1\n"; }
    validate_desktop_session
  ' _ "$SETUP" 2>&1); then
    fail 'missing D-Bus passed session guard'
  fi
  assert_contains "$output" 'desktop D-Bus session is required' 'D-Bus session error'

  if output=$(XDG_CURRENT_DESKTOP=ubuntu:GNOME DBUS_SESSION_BUS_ADDRESS=session bash -c '
    source "$1"
    gnome-shell() { printf "GNOME Shell 49.4\n"; }
    validate_desktop_session
  ' _ "$SETUP" 2>&1); then
    fail 'wrong GNOME version passed session guard'
  fi
  assert_contains "$output" 'GNOME Shell 50 is required' 'GNOME version error'

  XDG_CURRENT_DESKTOP=ubuntu:GNOME DBUS_SESSION_BUS_ADDRESS=session bash -c '
    source "$1"
    gnome-shell() { printf "GNOME Shell 50.1\n"; }
    validate_desktop_session
  ' _ "$SETUP"
}

test_architecture_mapping() {
  local output
  output=$(bash -c 'source "$1"; dpkg() { printf "amd64\\n"; }; detect_architecture; printf "%s" "$ARCH"' _ "$SETUP")
  assert_eq amd64 "$output" 'amd64 detection'

  output=$(bash -c 'source "$1"; dpkg() { printf "arm64\\n"; }; detect_architecture; printf "%s" "$ARCH"' _ "$SETUP")
  assert_eq arm64 "$output" 'arm64 detection'

  if output=$(bash -c 'source "$1"; dpkg() { printf "riscv64\\n"; }; detect_architecture' _ "$SETUP" 2>&1); then
    fail 'unsupported architecture passed detection'
  fi
  assert_contains "$output" 'unsupported architecture: riscv64' 'unsupported architecture error'

  assert_eq amd64 "$(bash -c 'source "$1"; helium_asset_arch amd64' _ "$SETUP")" 'Helium amd64 mapping'
  assert_eq arm64 "$(bash -c 'source "$1"; helium_asset_arch arm64' _ "$SETUP")" 'Helium arm64 mapping'
  if bash -c 'source "$1"; helium_asset_arch riscv64' _ "$SETUP" > /dev/null 2>&1; then
    fail 'unsupported Helium architecture was accepted'
  fi
}

test_sha_validation() {
  bash -c 'source "$1"; validate_sha256 "$2"' _ "$SETUP" \
    0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
  bash -c 'source "$1"; validate_sha256 "$2"' _ "$SETUP" \
    ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789

  if bash -c 'source "$1"; validate_sha256 "$2"' _ "$SETUP" deadbeef; then
    fail 'short SHA-256 was accepted'
  fi
  if bash -c 'source "$1"; validate_sha256 "$2"' _ "$SETUP" \
    z123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef; then
    fail 'non-hex SHA-256 was accepted'
  fi
}

test_release_asset_parsing() {
  local tmp digest output
  tmp=$(mktemp -d)
  digest=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
  printf '{"draft":false,"prerelease":false,"tag_name":"v1.2.3","assets":[{"name":"app_1.2.3_amd64.deb","browser_download_url":"https://example.com/app.deb","digest":"sha256:%s"}]}' \
    "$digest" > "$tmp/release.json"
  output=$(bash -c 'source "$1"; select_release_asset "$2" "$3" app' \
    _ "$SETUP" "$tmp/release.json" '^app_.+_amd64[.]deb$')
  assert_eq $'app_1.2.3_amd64.deb\thttps://example.com/app.deb\t'"$digest" \
    "$output" 'release asset selection'

  printf '{"draft":false,"prerelease":false,"tag_name":"v1","assets":[{"name":"app.deb","browser_download_url":"https://example.com/app.deb","digest":null}]}' \
    > "$tmp/invalid.json"
  if bash -c 'source "$1"; select_release_asset "$2" "$3" app' \
    _ "$SETUP" "$tmp/invalid.json" '^app[.]deb$' > /dev/null 2>&1; then
    rm -rf "$tmp"
    fail 'release asset without digest was accepted'
  fi
  rm -rf "$tmp"
}

test_source_metadata_helpers() {
  local digest source metadata
  digest=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
  source=https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.tar.xz
  bash -c 'source "$1"; pacstall_recipe_matches 3.4.0 "$2" "$3" 3.4.0 "$2"' \
    _ "$SETUP" "$digest" "$source"
  if bash -c 'source "$1"; pacstall_recipe_matches 3.3.0 "$2" "$3" 3.4.0 "$2"' \
    _ "$SETUP" "$digest" "$source"; then
    fail 'stale Pacstall recipe was accepted'
  fi

  assert_eq 0.14.5.1-1 \
    "$(bash -c 'source "$1"; helium_deb_version helium-bin_0.14.5.1-1_amd64.deb amd64' _ "$SETUP")" \
    'Helium package version parsing'
  if bash -c 'source "$1"; helium_deb_version helium.AppImage amd64' _ "$SETUP"; then
    fail 'invalid Helium asset filename was accepted'
  fi

  metadata='{"uuid":"example@test","version":9,"shell-version":["49","50"]}'
  bash -c 'source "$1"; extension_metadata_valid "$2" example@test 50 9' \
    _ "$SETUP" "$metadata"
  if bash -c 'source "$1"; extension_metadata_valid "$2" example@test 51 9' \
    _ "$SETUP" "$metadata"; then
    fail 'incompatible GNOME extension metadata was accepted'
  fi
}

test_flathub_remote_validation() {
  bash -c '
    source "$1"
    DRY_RUN=0
    flatpak() { printf "flathub\thttps://dl.flathub.org/repo/\n"; }
    verify_flathub_remote
  ' _ "$SETUP"
  if bash -c '
    source "$1"
    DRY_RUN=0
    flatpak() { printf "flathub\thttps://example.com/repo/\n"; }
    verify_flathub_remote
  ' _ "$SETUP" > /dev/null 2>&1; then
    fail 'unexpected Flathub remote URL was accepted'
  fi
}

test_gvariant_helpers() {
  local output
  output=$(bash -c 'source "$1"; gvariant_array alpha "two words" "one'"'"'quote"' _ "$SETUP")
  assert_eq "['alpha', 'two words', 'one\\'quote']" "$output" 'GVariant array rendering'

  bash -c 'source "$1"; array_contains beta alpha beta gamma' _ "$SETUP"
  if bash -c 'source "$1"; array_contains delta alpha beta gamma' _ "$SETUP"; then
    fail 'array membership returned a false positive'
  fi
}

test_manifest_and_sources() {
  local apt_expected apt_actual flatpak_expected flatpak_actual all output
  apt_expected=$(cat <<'EOF'
7zip
alacritty
bat
btop
build-essential
ca-certificates
curl
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
gnome-shell-extension-prefs
gnome-shell-ubuntu-extensions
gnome-software
gnome-software-plugin-flatpak
gnome-tweaks
gpg
i2c-tools
jq
less
nautilus
neovim
openssh-client
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
xdg-utils
xz-utils
zoxide
zsh
zsh-antidote
EOF
)
  apt_actual=$(bash -c 'source "$1"; printf "%s\\n" "${APT_PACKAGES[@]}"' _ "$SETUP")
  assert_eq "$apt_expected" "$apt_actual" 'APT manifest'

  flatpak_expected=$'com.bitwarden.desktop\ncom.fastmail.Fastmail\norg.localsend.localsend_app'
  flatpak_actual=$(bash -c 'source "$1"; printf "%s\\n" "${FLATPAK_APPS[@]}"' _ "$SETUP")
  assert_eq "$flatpak_expected" "$flatpak_actual" 'Flatpak manifest'

  all="$apt_actual"$'\n'"$flatpak_actual"
  for unwanted in snapd steam vlc nomacs xivlauncher zen-browser; do
    assert_not_contains "$all" "$unwanted" 'excluded software manifest'
  done

  output=$(bash -c '
    source "$1"
    DRY_RUN=1
    ARCH=amd64
    TEMP_DIR=/tmp/dotfiles-test
    install_apt_software
    install_fonts
    install_flatpaks
  ' _ "$SETUP")
  assert_contains "$output" 'apt-get install -y' 'APT source command'
  assert_contains "$output" 'code signal-desktop' 'vendor APT packages'
  assert_contains "$output" 'current nerd-fonts-jetbrains-mono from Pacstall' 'Pacstall font decision'
  assert_contains "$output" 'flatpak install --user' 'user Flatpak source command'
  for app in com.bitwarden.desktop com.fastmail.Fastmail org.localsend.localsend_app; do
    assert_contains "$output" "$app" 'Flatpak source selection'
  done
}

test_extension_pairs() {
  local actual expected
  expected=$'3193 blur-my-shell@aunetx\n9875 o-tiling@oliwebd.github.com\n3843 just-perfection-desktop@just-perfection\n1007 windowIsReady_Remover@nunofarruca@gmail.com\n10319 window-title-pro@eprahemi.github.io'
  actual=$(bash -c '
    source "$1"
    ((${#EXTENSION_IDS[@]} == ${#EXTENSION_UUIDS[@]}))
    for index in "${!EXTENSION_IDS[@]}"; do
      printf "%s %s\\n" "${EXTENSION_IDS[$index]}" "${EXTENSION_UUIDS[$index]}"
    done
  ' _ "$SETUP")
  assert_eq "$expected" "$actual" 'GNOME extension ID and UUID pairs'
}

test_extension_state_merge() {
  local output enabled disabled
  output=$(bash -c '
    source "$1"
    DRY_RUN=0
    read_gsettings_array() {
      case "$2" in
        enabled-extensions)
          printf "%s\n" custom@example.com ubuntu-dock@ubuntu.com
          ;;
        disabled-extensions)
          printf "%s\n" other-disabled@example.com blur-my-shell@aunetx
          ;;
      esac
    }
    gs_set() { printf "%s\t%s\t%s\n" "$1" "$2" "$3"; }
    configure_extension_state
  ' _ "$SETUP")
  enabled=$(awk -F '\t' '$2 == "enabled-extensions" {print $3}' <<< "$output")
  disabled=$(awk -F '\t' '$2 == "disabled-extensions" {print $3}' <<< "$output")

  assert_contains "$enabled" 'custom@example.com' 'unrelated enabled extension preservation'
  assert_contains "$enabled" 'blur-my-shell@aunetx' 'requested extension enablement'
  assert_contains "$enabled" 'ubuntu-appindicators@ubuntu.com' 'AppIndicator enablement'
  assert_not_contains "$enabled" 'ubuntu-dock@ubuntu.com' 'Ubuntu extension disablement'
  assert_contains "$disabled" 'other-disabled@example.com' 'unrelated disabled extension preservation'
  assert_contains "$disabled" 'ubuntu-dock@ubuntu.com' 'Ubuntu extension disabled list'
  assert_not_contains "$disabled" 'blur-my-shell@aunetx' 'requested extension removed from disabled list'
}

test_custom_shortcut_merge() {
  local output paths
  output=$(HOME=/tmp/dotfiles-test-home bash -c '
    source "$1"
    DRY_RUN=0
    read_gsettings_array() { printf "%s\n" /existing/custom/; }
    gs_set() { printf "%s\t%s\t%s\n" "$1" "$2" "$3"; }
    configure_custom_shortcuts
  ' _ "$SETUP")
  paths=$(awk -F '\t' '$2 == "custom-keybindings" {print $3}' <<< "$output")
  assert_contains "$paths" '/existing/custom/' 'unrelated shortcut preservation'
  assert_contains "$paths" 'dotfiles-browser/' 'browser shortcut registration'
  assert_contains "$paths" 'dotfiles-home/' 'home shortcut registration'
  assert_contains "$paths" 'dotfiles-signal/' 'Signal shortcut registration'
  assert_contains "$paths" 'dotfiles-fastmail/' 'Fastmail shortcut registration'
}

test_gsettings_dry_run() {
  local actual expected
  actual=$(HOME=/tmp/dotfiles-test-home bash -c '
    source "$1"
    DRY_RUN=1
    configure_gnome
  ' _ "$SETUP" | grep '^  \$ gsettings set ')

  expected=$(HOME=/tmp/dotfiles-test-home bash -c '
    source "$1"
    DRY_RUN=1
    format_command gsettings set org.gnome.shell disable-user-extensions false
    format_command gsettings set org.gnome.desktop.peripherals.keyboard repeat true
    format_command gsettings set org.gnome.desktop.peripherals.keyboard delay 250
    format_command gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 50
    format_command gsettings set org.gnome.mutter dynamic-workspaces false
    format_command gsettings set org.gnome.desktop.wm.preferences num-workspaces 7
    format_command gsettings set org.gnome.desktop.wm.preferences mouse-button-modifier "<Super>"
    format_command gsettings set org.gnome.desktop.wm.preferences resize-with-right-button true
    printf -v quote "\\047"
    for workspace in {1..7}; do
      switch_binding="[$quote<Super>$workspace$quote]"
      move_binding="[$quote<Super><Shift>$workspace$quote]"
      format_command gsettings set org.gnome.desktop.wm.keybindings "switch-to-workspace-$workspace" "$switch_binding"
      format_command gsettings set org.gnome.desktop.wm.keybindings "move-to-workspace-$workspace" "$move_binding"
      format_command gsettings set org.gnome.shell.keybindings "switch-to-application-$workspace" "[]"
    done
    base=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings
    set_custom_shortcut "$base/dotfiles-browser/" Helium helium "<Super>w"
    set_custom_shortcut "$base/dotfiles-home/" Home "nautilus --new-window $HOME" "<Super>e"
    set_custom_shortcut "$base/dotfiles-signal/" Signal signal-desktop "<Super>s"
    set_custom_shortcut "$base/dotfiles-fastmail/" Fastmail "flatpak run com.fastmail.Fastmail" "<Super>m"
  ' _ "$SETUP")
  assert_eq "$expected" "$actual" 'exact GNOME gsettings dry-run commands'

  for workspace in {1..7}; do
    assert_contains "$actual" "switch-to-workspace-$workspace" 'workspace focus binding'
    assert_contains "$actual" "move-to-workspace-$workspace" 'workspace move binding'
    assert_contains "$actual" "switch-to-application-$workspace" 'dock binding clearing'
  done
  assert_contains "$actual" \
    'custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/dotfiles-browser/' \
    'relocatable browser shortcut schema'
  assert_contains "$actual" 'command helium' 'Helium shortcut command'
  assert_contains "$actual" 'command signal-desktop' 'Signal shortcut command'
  assert_contains "$actual" 'command flatpak\ run\ com.fastmail.Fastmail' 'Fastmail shortcut command'
}

test_snap_purge_dry_run() {
  local tmp output
  tmp=$(mktemp -d)
  mkdir -p "$tmp/home/snap"
  printf 'keep\n' > "$tmp/home/snap/marker"
  printf 'root:x:0:0:root:/root:/bin/bash\ntest:x:1000:1000:test:%s:/bin/bash\n' \
    "$tmp/home" > "$tmp/passwd"

  output=$(HOME="$tmp/home" PASSWD_FILE="$tmp/passwd" bash -c '
    source "$1"
    DRY_RUN=1
    TEMP_DIR=/tmp/dotfiles-test
    purge_snap
  ' _ "$SETUP")

  assert_contains "$output" 'remove every installed Snap with snap remove --purge' 'Snap package purge plan'
  assert_contains "$output" 'apt-get purge -y snapd' 'snapd APT purge plan'
  assert_contains "$output" 'rm -rf /snap /var/cache/snapd /var/lib/snapd /var/snap' 'system Snap data purge plan'
  assert_contains "$output" "rm -rf -- $tmp/home/snap $tmp/home/.snap" 'all-user Snap data purge plan'
  [[ -f $tmp/home/snap/marker ]] || {
    rm -rf "$tmp"
    fail 'dry-run deleted Snap data'
  }
  rm -rf "$tmp"
}

test_secondary_user_snap_confirmation() {
  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/secondary/snap"
  printf 'root:x:0:0:root:%s/root:/bin/bash\nsecondary:x:1001:1001:user:%s/secondary:/bin/bash\n' \
    "$tmp" "$tmp" > "$tmp/passwd"
  PASSWD_FILE="$tmp/passwd" bash -c '
    source "$1"
    user_snap_data_present
  ' _ "$SETUP" || {
    rm -rf "$tmp"
    fail 'secondary user Snap data did not trigger confirmation state'
  }
  rm -rf "$tmp"
}

test_link_path_backup_and_idempotency() {
  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/home" "$tmp/source" "$tmp/home/.config"
  printf 'new\n' > "$tmp/source/config"
  printf 'old\n' > "$tmp/home/.config/example"

  HOME="$tmp/home" bash -c '
    source "$1"
    DRY_RUN=0
    info() { :; }
    source_path="$2/source/config"
    target="$HOME/.config/example"
    link_path "$source_path" "$target"
    [[ -L $target ]]
    [[ $(readlink "$target") == "$source_path" ]]
    [[ $(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type f | wc -l) -eq 1 ]]
    [[ $(< "$BACKUP_DIR/example") == old ]]
    link_path "$source_path" "$target"
    [[ $(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type f | wc -l) -eq 1 ]]
  ' _ "$SETUP" "$tmp"
  rm -rf "$tmp"
}

test_font_directory_safety() {
  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/home/.local/share/fonts/AdwaitaMonoNerdFont"
  printf 'user font\n' > "$tmp/home/.local/share/fonts/AdwaitaMonoNerdFont/custom.ttf"
  HOME="$tmp/home" bash -c '
    source "$1"
    DRY_RUN=0
    info() { :; }
    path="$HOME/.local/share/fonts/AdwaitaMonoNerdFont"
    prepare_font_directory "$path"
    [[ ! -e $path ]]
    [[ -f $BACKUP_DIR/AdwaitaMonoNerdFont/custom.ttf ]]

    mkdir -p "$path"
    printf "3.4.0\n" > "$path/.version"
    prepare_font_directory "$path"
    [[ ! -e $path ]]
  ' _ "$SETUP"
  rm -rf "$tmp"
}

test_legacy_helium_safety() {
  local tmp
  tmp=$(mktemp -d)
  mkdir -p "$tmp/home/AppImages" "$tmp/home/.local/share/applications"
  touch "$tmp/home/AppImages/helium.AppImage"
  printf 'Exec=/custom/helium\n' > "$tmp/home/.local/share/applications/helium.desktop"
  HOME="$tmp/home" bash -c '
    source "$1"
    DRY_RUN=0
    warn() { :; }
    remove_legacy_helium_appimage
    [[ -f $HOME/AppImages/helium.AppImage ]]
    printf "Exec=%s/AppImages/helium.AppImage\n" "$HOME" > "$HOME/.local/share/applications/helium.desktop"
    remove_legacy_helium_appimage
    [[ ! -e $HOME/AppImages/helium.AppImage ]]
    [[ ! -e $HOME/.local/share/applications/helium.desktop ]]
  ' _ "$SETUP"
  rm -rf "$tmp"
}

test_helium_dry_selection() {
  local output
  output=$(bash -c '
    source "$1"
    DRY_RUN=1
    ARCH=amd64
    install_helium
    ARCH=arm64
    install_helium
  ' _ "$SETUP")
  assert_contains "$output" 'latest stable Helium amd64 .deb' 'Helium amd64 asset selection'
  assert_contains "$output" 'latest stable Helium arm64 .deb' 'Helium arm64 asset selection'
  assert_contains "$output" 'verify GitHub digest' 'Helium digest requirement'
  assert_contains "$output" 'xdg-settings set default-web-browser helium.desktop' 'Helium default browser command'
}

test_neovim_config() {
  command -v nvim > /dev/null || return 0
  nvim --headless -u "$ROOT_DIR/nvim/init.lua" '+qall'
}

printf 'TAP version 13\n'
run_test 'argument parser accepts only --dry-run' test_parse_args
run_test 'Ubuntu 26.04 OS guard' test_os_guard
run_test 'GNOME desktop session guard' test_desktop_session_guard
run_test 'architecture mapping' test_architecture_mapping
run_test 'SHA-256 validation' test_sha_validation
run_test 'release asset parsing and digest validation' test_release_asset_parsing
run_test 'source metadata helpers' test_source_metadata_helpers
run_test 'Flathub remote validation' test_flathub_remote_validation
run_test 'GVariant arrays and membership' test_gvariant_helpers
run_test 'software manifests and source decisions' test_manifest_and_sources
run_test 'GNOME extension ID and UUID pairing' test_extension_pairs
run_test 'GNOME extension state merge' test_extension_state_merge
run_test 'custom shortcut merge' test_custom_shortcut_merge
run_test 'exact GNOME gsettings dry-run output' test_gsettings_dry_run
run_test 'Snap purge dry-run safety' test_snap_purge_dry_run
run_test 'secondary user Snap data confirmation' test_secondary_user_snap_confirmation
run_test 'dotfile backup and link idempotency' test_link_path_backup_and_idempotency
run_test 'font directory backup safety' test_font_directory_safety
run_test 'legacy Helium AppImage safety' test_legacy_helium_safety
run_test 'Helium architecture selection' test_helium_dry_selection
run_test 'Neovim native package compatibility' test_neovim_config
printf '1..%d\n' "$tests_run"
