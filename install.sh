#!/usr/bin/env bash
set -Eeuo pipefail

repo=$(cd -- "$(dirname -- "$(readlink -f "$0")")" && pwd)
dry_run=false
case ${1:-} in
  --dry-run) dry_run=true ;;
  '') ;;
  *)
    echo 'Usage: ./install.sh [--dry-run]' >&2
    exit 2
    ;;
esac
(($# <= 1)) || exit 2

if ((EUID == 0)); then
  if [[ -n ${SUDO_USER:-} && $SUDO_USER != root ]]; then
    exec sudo -H -u "$SUDO_USER" -- "$repo/install.sh" "$@"
  fi
  echo 'Run ./install.sh as your desktop user.' >&2
  exit 1
fi

export PATH="$HOME/.local/bin:$PATH"
config_home=${XDG_CONFIG_HOME:-$HOME/.config}
data_home=${XDG_DATA_HOME:-$HOME/.local/share}
stamp=$(date -u +%Y%m%dT%H%M%SZ)-$$
work=
trap '[[ -z $work ]] || rm -rf -- "$work"' EXIT
trap 'printf "Installation failed at line %s. Fix the error above and rerun ./install.sh.\n" "$LINENO" >&2' ERR

run() {
  printf '+'
  printf ' %q' "$@"
  printf '\n'
  "$dry_run" || "$@"
}

base_packages=(
  sys-kernel/installkernel
  sys-kernel/linux-firmware
  sys-boot/limine
  x11-drivers/nvidia-drivers
  net-misc/networkmanager
  sys-apps/dbus
  sys-apps/pciutils
  sys-apps/usbutils
  sys-auth/elogind
  net-misc/openssh
  app-admin/sudo
  sys-process/cronie
  gnome-base/gvfs
  net-dns/avahi
  sys-auth/nss-mdns
  net-print/cups
  net-wireless/bluez
  net-wireless/blueman
  app-shells/zsh
  app-portage/gentoolkit
  app-eselect/eselect-repository
  app-portage/eix
)
cli_packages=(
  app-arch/7zip
  app-text/tree
  sys-apps/bat
  sys-apps/eza
  sys-process/psmisc
  sys-apps/fd
  app-shells/fzf
  app-misc/television
  dev-vcs/git
  app-misc/jq
  dev-util/sh
  sys-apps/ripgrep
  dev-db/sqlite
  app-misc/trash-cli
  app-arch/unzip
  net-misc/wget
  app-arch/zip
  app-shells/zoxide
  app-shells/starship
  dev-vcs/lazygit
  sys-fs/gdu
  sys-apps/nvme-cli
  sys-process/btop
  app-misc/fastfetch
  app-containers/podman
  app-containers/podman-compose
  app-containers/podman-tui
  net-misc/curl
)
desktop_packages=(
  gui-wm/mangowm
  x11-misc/ly
  gui-apps/waybar
  x11-misc/rofi
  x11-terms/wezterm
  app-misc/yazi
  app-text/zathura
  app-text/zathura-pdf-mupdf
  app-text/zathura-cb
  app-text/zathura-djvu
  media-video/mpv
  mpv-plugin/mpv-mpris
  x11-misc/pcmanfm
  '>=gui-apps/wl-clipboard-2.3.0'
  app-misc/cliphist
  gui-apps/swaylock
  gui-apps/swayidle
  gui-apps/swaybg
  gui-apps/wlopm
  x11-misc/dunst
  x11-misc/gammastep
  media-sound/playerctl
  media-sound/wiremix
  media-video/pipewire
  media-video/wireplumber
  media-sound/cava
  sci-calculators/qalculate-gtk
  sci-libs/libqalculate
  app-arch/file-roller
  sys-apps/gnome-disk-utility
  media-gfx/imv
  gnome-extra/polkit-gnome
  sys-fs/udiskie
  x11-misc/xdg-utils
  x11-misc/xdg-user-dirs
  sys-apps/xdg-desktop-portal-gtk
  gui-libs/xdg-desktop-portal-wlr
  x11-libs/libnotify
  media-video/ffmpeg
  media-video/ffmpegthumbnailer
  media-sound/alsa-utils
  app-misc/ddcutil
  media-video/libva-utils
  media-libs/nvidia-vaapi-driver
  x11-apps/mesa-progs
  dev-util/vulkan-tools
  sys-process/nvtop
  media-gfx/zbar
  app-text/tesseract
  app-dicts/myspell-en
  gui-apps/grim
  gui-apps/slurp
  app-text/xmlstarlet
  sys-apps/keyutils
  app-crypt/pinentry
  gnome-base/gnome-keyring
  gnome-base/gsettings-desktop-schemas
  gnome-base/dconf
  gui-apps/qt6ct
  x11-themes/papirus-icon-theme
  x11-themes/adwaita-icon-theme
  media-fonts/adwaita-fonts
  media-fonts/nerdfonts
  media-fonts/noto
  media-fonts/noto-cjk
  media-fonts/noto-emoji
)
app_packages=(
  app-misc/openrgb
  media-video/gpu-screen-recorder
  net-vpn/ivpn
)
dev_packages=(
  sys-devel/gcc
  dev-build/make
  sys-apps/bubblewrap
  dev-build/cmake
  app-editors/neovim
  dev-python/uv
  net-libs/nodejs
  dev-util/tree-sitter-cli
  dev-lang/zig
  dev-util/github-cli
)
binary_packages=(
  sys-kernel/gentoo-kernel-bin
  www-client/zen-browser-bin
  net-im/signal-desktop-bin
  app-office/onlyoffice-bin
  app-admin/bitwarden-desktop-bin
  app-admin/bitwarden-cli-bin
  mail-client/fastmail-desktop-bin
  net-misc/localsend-bin
  net-vpn/ivpn-ui-bin
  sys-apps/pnpm-bin
  media-sound/easyeffects
  app-misc/anki
)

install_system_file() {
  local source=$1 target=$2 mode=${3:-644} parent
  # Privileged files must be root-owned copies, never links into a user checkout.
  parent=$target
  while [[ $parent != / ]]; do
    [[ ! -L $parent ]] || {
      echo "Refusing system symlink: $parent" >&2
      exit 1
    }
    parent=$(dirname -- "$parent")
  done
  if [[ -f $target ]] && cmp -s -- "$source" "$target"; then
    return
  fi
  if [[ -e $target ]]; then
    run sudo install -d -m 700 -- "/var/backups/dotfiles/$stamp$(dirname -- "$target")"
    run sudo cp -a -- "$target" "/var/backups/dotfiles/$stamp$target"
  fi
  run sudo install -D -o root -g root -m "$mode" -- "$source" "$target"
}

install_system_config() {
  local source relative mode
  while IFS= read -r -d '' source; do
    relative=${source#"$repo/"}
    install_system_file "$source" "/$relative"
  done < <(find "$repo/etc" -type f -print0 | sort -z)
  while IFS= read -r -d '' source; do
    relative=${source#"$repo/overlay/"}
    install_system_file "$source" "/var/db/repos/dotfiles/$relative"
  done < <(find "$repo/overlay" -type f -print0 | sort -z)
  while IFS= read -r -d '' source; do
    relative=${source#"$repo/rootfs/"}
    mode=644
    [[ ! -x $source ]] || mode=755
    install_system_file "$source" "/$relative" "$mode"
  done < <(find "$repo/rootfs" -type f -print0 | sort -z)
}

sync_overlays() {
  local overlay
  run sudo emerge -qn app-eselect/eselect-repository dev-vcs/git
  for overlay in guru gentoo-zh waffle-builds; do
    if [[ ! -f /var/db/repos/$overlay/profiles/repo_name ]]; then
      run sudo emaint sync --repo "$overlay"
    fi
  done
}

install_packages() {
  local -a source_packages=("${base_packages[@]}" "${cli_packages[@]}"
    "${desktop_packages[@]}" "${app_packages[@]}" "${dev_packages[@]}")
  run sudo emerge -vn "${source_packages[@]}"
  run sudo emerge -gvn "${binary_packages[@]}"
  run sudo eix-update
}

enable_services() {
  local service runlevel
  local services=(dbus elogind NetworkManager cronie bluetooth cupsd avahi-daemon ivpn ly)
  if ! "$dry_run"; then
    for service in "${services[@]}"; do
      [[ -x /etc/init.d/$service ]] || {
        echo "Missing OpenRC service: $service" >&2
        return 1
      }
    done
  fi

  # Ly owns tty2 and NetworkManager owns DHCP; drop the competitors for the next boot.
  for service in display-manager xdm dhcpcd agetty.tty2; do
    for runlevel in boot default; do
      if [[ -L /etc/runlevels/$runlevel/$service ]]; then
        run sudo rc-update del "$service" "$runlevel"
      fi
    done
  done
  if [[ -f /etc/inittab ]] && grep -qE '^[^#].*[[:space:]]tty2[[:space:]]' /etc/inittab; then
    run sudo install -d -m 700 -- "/var/backups/dotfiles/$stamp/etc"
    run sudo cp -a -- /etc/inittab "/var/backups/dotfiles/$stamp/etc/inittab"
    run sudo sed -i '/^[^#].*[[:space:]]tty2[[:space:]]/s/^/#/' /etc/inittab
  fi
  for service in "${services[@]}"; do
    run sudo rc-update add "$service" default
  done
}

link() {
  local source=$1 target=$2 backup

  [[ -e $source ]] || {
    echo "Missing source: $source" >&2
    exit 1
  }
  [[ -L $target && $(readlink "$target") == "$source" ]] && return
  printf 'link %s -> %s\n' "$target" "$source"
  "$dry_run" && return
  mkdir -p -- "$(dirname "$target")"

  if [[ -e $target || -L $target ]]; then
    backup=$target.before-gentoo-$stamp
    [[ ! -e $backup && ! -L $backup ]] || exit 1
    mv -T -- "$target" "$backup"
    printf 'backup %s\n' "$backup"
  fi
  ln -sfnT -- "$source" "$target"
}

link_dotfiles() {
  local name desktop script target

  for name in bat btop cava dunst fastfetch fontconfig nvim qt6ct rofi zathura \
    mango swaylock waybar wezterm yazi \
    xdg-desktop-portal; do
    link "$repo/config/$name" "$config_home/$name"
  done

  link "$repo/config/mpv/mpv.conf" "$config_home/mpv/mpv.conf"
  link "$repo/config/mpv/script-opts" "$config_home/mpv/script-opts"
  link "$repo/config/zsh/zshrc" "$HOME/.zshrc"
  link "$repo/config/starship/starship.toml" "$config_home/starship.toml"
  link "$repo/config/rsync-home.excludes" "$config_home/rsync-home.excludes"
  link "$repo/config/xorg/keymap.xkb" "$config_home/xkb/symbols/aileks"
  link "$repo/config/wallpaper/fantasy-woods.jpg" "$data_home/backgrounds/fantasy-woods.jpg"
  link "$repo/config/OpenRGB/No RGB.orp" "$config_home/OpenRGB/No RGB.orp"
  link "$repo/config/television/cable/portage.toml" "$config_home/television/cable/portage.toml"

  # Theme installers generate GTK CSS, so link only the settings files.
  for name in gtk-3.0 gtk-4.0; do
    target=$config_home/$name
    if [[ -L $target && $(readlink "$target") == "$repo/config/$name" ]]; then
      printf 'replace GTK directory link: %s\n' "$target"
      if ! "$dry_run"; then
        mv -T -- "$target" "$target.before-gentoo-$stamp"
        mkdir -p -- "$target"
      fi
    fi
    link "$repo/config/$name/settings.ini" "$target/settings.ini"
  done

  for desktop in "$repo/config/applications/"*.desktop; do
    link "$desktop" "$data_home/applications/${desktop##*/}"
  done

  for script in "$repo/bin/"*; do
    link "$script" "$HOME/.local/bin/${script##*/}"
  done
}

install_user_tools() {
  local work=$work/user-tools
  if "$dry_run"; then
    printf 'install antidote, bemoji, and ModernZ\n'
    return
  fi
  mkdir -p "$work" "$HOME/.local/bin" "$data_home"
  if [[ ! -e $HOME/.antidote ]]; then
    git clone --depth 1 https://github.com/mattmc3/antidote.git "$HOME/.antidote"
  fi
  [[ -r $HOME/.antidote/antidote.zsh ]] || {
    echo 'Antidote checkout is incomplete: ~/.antidote' >&2
    return 1
  }

  git clone --depth 1 https://github.com/marty-oehme/bemoji.git "$work/bemoji"
  install -b -m 755 "$work/bemoji/bemoji" "$HOME/.local/bin/bemoji"
  mkdir -p "$data_home/bemoji"
  if [[ ! -s $data_home/bemoji/emojis.txt ]]; then
    curl --fail --location https://www.unicode.org/Public/17.0.0/emoji/emoji-test.txt \
      --output "$work/emoji-test.txt"
    sed -n 's/^.*; fully-qualified.*# \([^[:space:]]*\) [^[:space:]]* \(.*$\)/\1 \2/p' \
      "$work/emoji-test.txt" >"$work/emojis.txt"
    [[ -s $work/emojis.txt ]]
    install -m 644 "$work/emojis.txt" "$data_home/bemoji/emojis.txt"
  fi

  git clone --depth 1 https://github.com/Samillion/ModernZ.git "$work/modernz"
  mkdir -p "$config_home/mpv/scripts" "$config_home/mpv/fonts"
  install -b -m 644 "$work/modernz/modernz.lua" "$config_home/mpv/scripts/modernz.lua"
  install -b -m 644 "$work/modernz/modernz-icons.ttf" "$config_home/mpv/fonts/modernz-icons.ttf"
}

install_appearance() {
  local work=$work/appearance
  local theme name
  if "$dry_run"; then
    printf 'install Cinder Grove GTK theme and recolored Papirus icons\n'
    return
  fi
  [[ -d /usr/share/icons/Papirus-Dark ]] || {
    echo 'Install Papirus first.' >&2
    return 1
  }
  mkdir -p "$work"

  replace() {
    local source=$1 target=$2
    if [[ ! -L $target && -e $target ]] && diff -qr -- "$source" "$target" >/dev/null; then
      return
    fi
    mkdir -p -- "$(dirname -- "$target")"
    if [[ -e $target || -L $target ]]; then
      mv -T -- "$target" "$target.before-appearance-$stamp"
    fi
    cp -a -- "$source" "$target"
  }

  git clone --depth 1 https://github.com/aileks/cinder-grove-gtk.git "$work/gtk"
  theme=$data_home/themes/Cinder-Grove-Dark
  replace "$work/gtk/Cinder-Grove-Dark" "$theme"
  # GTK4 needs the theme CSS and the accent definitions in the user CSS.
  cat "$theme/gtk-4.0/cinder-grove.css" "$theme/gtk-4.0/accent.css" >"$work/gtk.css"
  [[ ! -L $config_home/gtk-4.0 ]] || {
    echo 'Run install.sh to replace the old GTK directory link first.' >&2
    return 1
  }
  replace "$work/gtk.css" "$config_home/gtk-4.0/gtk.css"

  git clone --depth 1 --branch cinder-grove-folders \
    https://github.com/aileks/papirus-folders.git "$work/folders"
  mkdir -p "$work/icons" "$HOME/.local/bin"
  install -m 755 "$work/folders/papirus-folders-cg" "$work/papirus-folders-cg"
  for name in Papirus Papirus-Dark Papirus-Light; do
    cp -a -- "/usr/share/icons/$name" "$work/icons/$name"
    chmod -R u+w "$work/icons/$name"
  done
  USER_HOME="$work" XDG_CONFIG_HOME="$work/config" XDG_DATA_HOME="$work" XDG_DATA_DIRS="$work" \
    "$work/papirus-folders-cg" --theme Papirus-Dark --color grove
  for name in Papirus Papirus-Dark Papirus-Light; do
    replace "$work/icons/$name" "$data_home/icons/$name"
  done
  replace "$work/papirus-folders-cg" "$HOME/.local/bin/papirus-folders-cg"
}

setup_mime() {
  local directory name
  local -A installed=() resolved=() missing=()
  local policy mime browser target existing backup temporary
  if "$dry_run"; then
    printf 'set MIME defaults from config/xdg/mime-policy.json\n'
    return
  fi

  for directory in "$data_home/applications" /usr/local/share/applications /usr/share/applications; do
    [[ -d $directory ]] || continue
    for name in "$directory/"*.desktop; do
      installed[${name##*/}]=$name
    done
  done

  browser=zen-browser-bin.desktop
  [[ -v installed[$browser] ]] || {
    echo "Missing desktop entry: $browser" >&2
    return 1
  }

  policy=$(jq -er 'to_entries[] | [.key, .value[0]] | @tsv' "$repo/config/xdg/mime-policy.json")
  while IFS=$'\t' read -r mime name; do
    [[ -v installed[$name] ]] || missing[$name]=1
    resolved[$mime]=$name
  done <<<"$policy"

  if ((${#missing[@]})); then
    echo 'Install or resolve these desktop IDs first:' >&2
    printf '  %s\n' "${!missing[@]}" | sort >&2
    return 1
  fi

  for mime in "${!resolved[@]}"; do
    printf '%s=%s;\n' "$mime" "${resolved[$mime]}"
  done | sort >"$work/mime-defaults"

  target=$config_home/mimeapps.list
  existing=/dev/null
  [[ -f $target ]] && existing=$target

  # Merge only the managed defaults, retaining unrelated entries and sections.
  awk '
    function remaining( key) {
      for (key in defaults)
        if (!written[key]++) print key "=" defaults[key]
    }
    FILENAME == ARGV[1] {
      key = substr($0, 1, index($0, "=") - 1)
      defaults[key] = substr($0, index($0, "=") + 1)
      next
    }
    /^\[/ {
      if (section) remaining()
      section = ($0 ~ /^\[Default Applications\][[:space:]]*$/)
      if (section) found = 1
    }
    section && /^[^#;=]+=/ {
      key = substr($0, 1, index($0, "=") - 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
      if (key in defaults) {
        if (!written[key]++) print key "=" defaults[key]
        next
      }
    }
    { print }
    END {
      if (!found) print "\n[Default Applications]"
      remaining()
    }
  ' "$work/mime-defaults" "$existing" >"$work/mimeapps.list.merged"
  chmod 600 "$work/mimeapps.list.merged"

  if [[ -f $target ]] && cmp -s "$work/mimeapps.list.merged" "$target"; then
    rm -- "$work/mimeapps.list.merged"
  else
    if [[ -e $target || -L $target ]]; then
      backup=$target.before-gentoo-$stamp
      [[ ! -e $backup && ! -L $backup ]] || {
        echo 'MIME backup already exists' >&2
        return 1
      }
      mv -T -- "$target" "$backup"
    fi
    mv -- "$work/mimeapps.list.merged" "$target"
  fi

  xdg-settings set default-web-browser "$browser"

  for mime in x-scheme-handler/http x-scheme-handler/https text/html application/xhtml+xml; do
    if [[ $(xdg-mime query default "$mime") != "$browser" ]]; then
      echo "MIME default verification failed for $mime" >&2
      return 1
    fi
  done
}

install_crontab() {
  if "$dry_run"; then
    printf 'merge config/cron/crontab into the user crontab (preserve unrelated jobs)\n'
    return
  fi
  if ! LC_ALL=C crontab -l >"$work/crontab" 2>"$work/crontab-error"; then
    grep -q '^no crontab for ' "$work/crontab-error" || {
      cat "$work/crontab-error" >&2
      return 1
    }
  fi
  awk '/^# BEGIN dotfiles$/ { managed=1; next }
       /^# END dotfiles$/ { managed=0; next }
       !managed { print }
       END { if (managed) exit 1 }' "$work/crontab" >"$work/crontab-new"
  {
    echo '# BEGIN dotfiles'
    cat "$repo/config/cron/crontab"
    echo '# END dotfiles'
  } >>"$work/crontab-new"
  if ! cmp -s "$work/crontab" "$work/crontab-new"; then
    mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
    cp "$work/crontab" "${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/crontab-$stamp"
    crontab "$work/crontab-new"
  fi
}

if ! "$dry_run"; then
  [[ -f /etc/gentoo-release && -d /etc/runlevels ]] || {
    echo 'This installer requires a booted Gentoo OpenRC system.' >&2
    exit 1
  }
  sudo -v
  work=$(mktemp -d)
fi

run git -C "$repo" submodule update --init --recursive
install_system_config
sync_overlays
install_packages
enable_services
link_dotfiles
install_user_tools
install_appearance
run dbus-run-session -- gsettings set org.gnome.desktop.interface gtk-theme Cinder-Grove-Dark
run dbus-run-session -- gsettings set org.gnome.desktop.interface color-scheme prefer-dark
run dbus-run-session -- gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark
run dbus-run-session -- gsettings set org.gnome.desktop.interface cursor-theme Adwaita
run dbus-run-session -- gsettings set org.gnome.desktop.interface cursor-size 24
run dbus-run-session -- gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans 11'
run dbus-run-session -- gsettings set org.gnome.desktop.interface monospace-font-name 'Iosevka Nerd Font 12'
run dbus-run-session -- gsettings set org.gnome.desktop.interface clock-format 24h
run dbus-run-session -- gsettings set org.gnome.desktop.wm.preferences button-layout ''
run xdg-user-dirs-update
setup_mime
run fc-cache -f
run bat cache --build
install_crontab

if "$dry_run"; then
  echo 'Dry run complete; no changes made.'
else
  echo 'Installation complete. Reboot to start the configured OpenRC services and Mango session.'
fi
