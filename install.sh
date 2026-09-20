#!/usr/bin/env bash

set -Eeuo pipefail

repo=$(readlink -f -- "${BASH_SOURCE[0]}")
repo=${repo%/*}

dry_run=false
target_user=
target_home=
target_uid=
config_home=
data_home=
stamp=
work=
cleanup_directory=
gpu_vendor=
void_packages=

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}

select_user() {
  local account

  if ((EUID == 0)); then
    target_user=${SUDO_USER:-}
    [[ -n $target_user ]] || target_user=$(stat -c %U -- "$repo")
  else
    target_user=$(id -un)
  fi

  [[ -n $target_user && $target_user != root ]] || fail 'Could not determine the desktop account to install for.'
  account=$(getent passwd "$target_user") || fail "No such account: $target_user"
  IFS=: read -r target_user _ target_uid _ _ target_home _ <<<"$account"
  [[ $target_uid != 0 && $target_home == /* && -d $target_home ]] || fail 'The desktop account must have an existing home directory and a nonzero UID.'

  config_home=$target_home/.config
  data_home=$target_home/.local/share
}

run() {
  printf '+'
  printf ' %q' "$@"
  printf '\n'
  "$dry_run" || "$@"
}

as_user() {
  runuser -u "$target_user" -- env -i \
    HOME="$target_home" USER="$target_user" LOGNAME="$target_user" \
    PATH="$target_home/.local/bin:/usr/local/bin:/usr/bin:/bin" \
    XDG_CONFIG_HOME="$config_home" XDG_DATA_HOME="$data_home" \
    LANG="${LANG:-C.UTF-8}" TERM="${TERM:-dumb}" "$@"
}

check_system_target() {
  local target=$1 parent=$1

  while [[ $parent != / ]]; do
    [[ ! -L $parent ]] || fail "Refusing system symlink: $parent"
    if [[ $parent != "$target" && -e $parent && ! -d $parent ]]; then
      fail "Expected a directory at $parent. Preserve its contents in a directory before rerunning."
    fi

    parent=${parent%/*}
    [[ -n $parent ]] || parent=/
  done

  [[ ! -d $target ]] || fail "Expected a file at $target."
}

detect_gpu() {
  local device class vendor

  gpu_vendor=
  shopt -s nullglob
  for device in /sys/bus/pci/devices/*; do
    read -r class <"$device/class" 2>/dev/null || continue
    [[ $class == 0x0300* || $class == 0x0302* ]] || continue
    read -r vendor <"$device/vendor" 2>/dev/null || continue
    case $vendor in
      0x10de) gpu_vendor=nvidia ;;
      0x1002) gpu_vendor=amd ;;
      *) continue ;;
    esac
    break
  done
  shopt -u nullglob
}

preflight() {
  local source relative booted_root

  [[ $(. /etc/os-release 2>/dev/null && echo "$ID") == void ]] || fail 'This installer requires Void Linux.'
  command -v xbps-install >/dev/null 2>&1 || fail 'xbps-install not found.'

  booted_root=$(stat -Lc '%d:%i' /proc/1/root 2>/dev/null || true)
  if [[ -n $booted_root && $(stat -Lc '%d:%i' /) != "$booted_root" ]]; then
    fail 'The target is not the booted root.'
  fi

  [[ $repo == "$target_home/"* && -d $repo/.git ]] || fail 'Keep a Git checkout inside the desktop user home before running this installer.'
  [[ $(stat -c %u "$repo") == "$target_uid" ]] || fail "The checkout must belong to $target_user."

  while IFS= read -r -d '' source; do
    relative=${source#"$repo/"}
    check_system_target "/$relative"
  done < <(find "$repo/etc" -type f -not -path "$repo/etc/portage/*" -print0)

  dry_run=true link_dotfiles >/dev/null

  if [[ -e $config_home/emacs || -L $config_home/emacs ]]; then
    [[ -x $config_home/emacs/bin/doom && -d $config_home/emacs/.git ]] || fail "Incomplete or unrelated Emacs installation at $config_home/emacs; preserve it elsewhere before rerunning."
  fi

  detect_gpu
  case $gpu_vendor in
    nvidia) printf 'GPU: NVIDIA, installing the proprietary driver\n' ;;
    amd) printf 'GPU: AMD, using Mesa\n' ;;
    *) printf 'GPU: no NVIDIA or AMD graphics controller, skipping vendor drivers\n' ;;
  esac
}

packages=(
  linux-firmware NetworkManager network-manager-applet dbus-elogind elogind polkit-elogind pciutils usbutils openssh
  opendoas avahi nss-mdns cups bluez blueman gst-plugins-base1 gst-plugins-good1 gst-plugins-bad1 gst-plugins-ugly1
  gst-libav docker docker-compose 7zip tree bat eza psmisc fd fzf git jq shfmt ripgrep sqlite trash-cli unzip wget
  rsync zip zoxide nvme-cli btop fastfetch curl github-cli xorg-server xinit xauth xorg-apps xf86-input-libinput slop
  xkeyboard-config alsa-pipewire pipewire wireplumber-elogind pulseaudio-utils j4-dmenu-desktop maim xclip xdotool xtools
  xss-lock clipmenu xwallpaper xautolock pkg-config fontconfig nnn zathura zathura-pdf-mupdf zathura-cb zathura-djvu uv
  mpv mpv-mpris pcmanfm lxappearance dunst libnotify playerctl wiremix cava qalculate-gtk file-roller ncdu2 imv udiskie
  tumbler xdg-utils xdg-user-dirs gvfs polkit-gnome xdg-desktop-portal-gtk ffmpeg6 ffmpegthumbnailer alsa-utils ddcutil
  libva-utils mesa-demos Vulkan-Tools nvtop cronie tesseract-ocr tesseract-ocr-eng hunspell-en keyutils pinentry dconf
  gnome-keyring gsettings-desktop-schemas qt6ct papirus-icon-theme adwaita-icon-theme adwaita-fonts noto-fonts-ttf openrgb
  noto-fonts-cjk noto-fonts-emoji gpu-screen-recorder Signal-Desktop fontconfig-devel freetype-devel imlib2-devel openjdk21 
  libX11-devel libXcursor-devel libXext-devel libXft-devel libXinerama-devel libXrandr-devel libXrender-devel libxcb-devel
  libxcrypt-devel xcb-util-devel clang gcc gdb make bubblewrap cmake neovim libvterm tree-sitter-cli libgccjit-devel
  jansson-devel tree-sitter-devel gtk+3-devel cairo-devel harfbuzz-devel giflib-devel libjpeg-turbo-devel libpng-devel
  librsvg-devel libwebp-devel libxml2-devel gnutls-devel texinfo autoconf automake
)

custom_packages=(
  zig
  zls
  zen-browser
  helium
  localsend
  onlyoffice-desktopeditors
  bitwarden-desktop
)

install_system_file() {
  local source=$1 target=$2 mode=${3:-644}

  check_system_target "$target"

  if [[ -f $target ]] && cmp -s -- "$source" "$target"; then
    if [[ $(stat -c '%u:%g:%a' "$target") != "0:0:$mode" ]]; then
      run chown root:root -- "$target"
      run chmod "$mode" -- "$target"
    fi
    return
  fi

  if [[ -e $target ]]; then
    run install -d -m 700 -- "/var/backups/dotfiles/$stamp${target%/*}"
    run cp -a -- "$target" "/var/backups/dotfiles/$stamp$target"
  fi

  run install -D -o root -g root -m "$mode" -- "$source" "$target"
}

install_system_config() {
  local source relative

  while IFS= read -r -d '' source; do
    relative=${source#"$repo/"}
    install_system_file "$source" "/$relative"
  done < <(find "$repo/etc" -type f -not -path "$repo/etc/portage/*" -print0 | sort -z)
}

install_xkb() {
  local xkb_root=/usr/share/X11/xkb
  [[ ! -L $xkb_root ]] || xkb_root=$(readlink -f "$xkb_root")
  install_system_file "$repo/config/xkb/symbols/custom" "$xkb_root/symbols/custom"
}

install_missing() {
  local package
  local -a missing=()

  for package in "$@"; do
    xbps-query "$package" >/dev/null 2>&1 || missing+=("$package")
  done

  if ((${#missing[@]} > 0)); then
    run xbps-install -Sy "${missing[@]}"
  fi
}

install_packages() {
  run xbps-install -Suy xbps
  install_missing void-repo-nonfree

  case $gpu_vendor in
    nvidia)
      packages+=(nvidia nvidia-vaapi-driver)
      ;;
    amd | '')
      :
      ;;
  esac

  install_missing "${packages[@]}"
}

install_suckless() {
  local name
  for name in dwm st dmenu slock dwmblocks; do
    run make -C "$repo/config/$name" clean install
  done
  if [[ ! -d $target_home/.terminfo ]]; then
    run as_user tic -sx "$repo/config/st/st.info"
  fi
}

emacs_version=30.2

install_emacs() {
  if [[ -x /usr/local/bin/emacs ]] && ldd /usr/local/bin/emacs 2>/dev/null | grep -q libgccjit; then
    printf 'emacs already built with native compilation\n'
    return
  fi

  local source_dir=$target_home/src/emacs-$emacs_version
  if [[ ! -d $source_dir ]]; then
    run as_user git clone --depth 1 -b "emacs-$emacs_version" https://github.com/emacs-mirror/emacs.git "$source_dir"
  fi

  run as_user bash -c "cd '$source_dir' && ./autogen.sh"
  run as_user bash -c "cd '$source_dir' && ./configure --prefix=/usr/local --with-x-toolkit=gtk3 --with-cairo --with-harfbuzz --with-xft --with-native-compilation --with-json --with-tree-sitter --with-modules --with-rsvg --with-webp --with-gif --with-jpeg --with-png --with-xinput2"
  run as_user make -C "$source_dir" -j"$(nproc)"
  run make -C "$source_dir" install
}

sync_custom_templates() {
  local template

  for template in "$repo"/templates/*/; do
    template=${template%/}
    run as_user rsync -a --delete "$template/" "$void_packages/srcpkgs/${template##*/}/"
  done
}

build_custom_packages() {
  local package
  local -a missing=()

  for package in "${custom_packages[@]}"; do
    xbps-query "$package" >/dev/null 2>&1 || missing+=("$package")
  done

  if ((${#missing[@]} == 0)); then
    return
  fi

  if [[ ! -d $void_packages ]]; then
    run as_user git clone --depth 1 https://github.com/void-linux/void-packages.git "$void_packages"
  fi

  sync_custom_templates

  run as_user "$void_packages/xbps-src" binary-bootstrap

  for package in "${missing[@]}"; do
    run as_user "$void_packages/xbps-src" pkg "$package"
  done
}

install_custom_packages() {
  local repository=$void_packages/hostdir/binpkgs
  local package
  local -a missing=()

  printf 'repository=%s\n' "$repository" >"$work/xbps-dotfiles.conf"
  install_system_file "$work/xbps-dotfiles.conf" /etc/xbps.d/10-dotfiles-repository.conf 644

  for package in "${custom_packages[@]}"; do
    xbps-query "$package" >/dev/null 2>&1 || missing+=("$package")
  done

  if ((${#missing[@]} > 0)); then
    run xbps-install -y --repository "$repository" "${missing[@]}"
  fi
  run xbps-pkgdb -m repolock "${custom_packages[@]}"
}

configure_account() {
  local shell account

  shell=$(command -v bash || true)
  if "$dry_run"; then
    printf 'set %s login shell to Bash and add i2c and docker membership if missing\n' "$target_user"
  else
    [[ -n $shell ]] || fail 'Bash was not installed.'
    shell=$(readlink -f "$shell")
    grep -Fxq "$shell" /etc/shells || fail "Bash is not listed in /etc/shells: $shell"
    account=$(getent passwd "$target_user") || fail "No such account: $target_user"
    if [[ ${account##*:} != "$shell" ]]; then
      run usermod -s "$shell" "$target_user"
    fi

    if ! getent group i2c >/dev/null; then
      run groupadd --system i2c
    fi

    if [[ " $(id -nG "$target_user") " != *' i2c '* ]]; then
      run usermod -aG i2c "$target_user"
    fi

    if [[ " $(id -nG "$target_user") " != *' docker '* ]]; then
      run usermod -aG docker "$target_user"
    fi
  fi
}

configure_mdns() {
  if "$dry_run"; then
    printf 'enable mDNS lookup in /etc/nsswitch.conf, preserving other lookup rules\n'
    return
  fi

  awk '
    /^hosts:[[:space:]]/ {
      found=1
      if ($0 !~ /(^|[[:space:]])mdns(4|6)?(_minimal)?([[:space:]]|$)/) {
        if (!sub(/(^|[[:space:]])files([[:space:]]|$)/, " files mdns4_minimal [NOTFOUND=return] ")) exit 1
      }
    }
    { print }
    END { if (!found) exit 1 }
  ' /etc/nsswitch.conf >"$work/nsswitch.conf" || fail 'Expected a hosts lookup containing files in /etc/nsswitch.conf.'
  install_system_file "$work/nsswitch.conf" /etc/nsswitch.conf
}

configure_pipewire() {
  local source target

  if "$dry_run"; then
    printf 'enable the wireplumber and pipewire-pulse session configs system wide\n'
    return
  fi

  run install -d -m 755 /etc/pipewire/pipewire.conf.d
  for source in /usr/share/examples/wireplumber/10-wireplumber.conf /usr/share/examples/pipewire/20-pipewire-pulse.conf; do
    [[ -f $source ]] || fail "Missing PipeWire example config: $source"
    target=/etc/pipewire/pipewire.conf.d/${source##*/}
    if [[ ! -L $target ]]; then
      run ln -s "$source" "$target"
    fi
  done
}

enable_services() {
  local service
  local services=(dbus elogind NetworkManager cronie bluetoothd cupsd avahi-daemon docker)

  for service in "${services[@]}"; do
    run ln -sfn "/etc/sv/$service" "/var/service/$service"
  done

  if [[ -L /var/service/dhcpcd ]]; then
    run rm /var/service/dhcpcd
  fi
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
    backup=$target.backup.$stamp
    [[ ! -e $backup && ! -L $backup ]] || exit 1
    mv -T -- "$target" "$backup"
    printf 'backup %s\n' "$backup"
  fi

  ln -sfnT -- "$source" "$target"
}

link_dotfiles() {
  local config_dir desktop script

  for config_dir in bat btop cava dunst fastfetch fontconfig doom zathura nnn nvim; do
    link "$repo/config/$config_dir" "$config_home/$config_dir"
  done

  link "$repo/config/qt6ct/colors" "$config_home/qt6ct/colors"
  link "$repo/config/qt6ct/qt6ct.conf" "$config_home/qt6ct/qt6ct.conf"
  link "$repo/config/mpv/mpv.conf" "$config_home/mpv/mpv.conf"
  link "$repo/config/mpv/script-opts" "$config_home/mpv/script-opts"
  link "$repo/config/bash/bashrc" "$target_home/.bashrc"
  link "$repo/config/bash/bash_profile" "$target_home/.bash_profile"
  link "$repo/config/x11/Xresources" "$target_home/.Xresources"
  link "$repo/config/x11/xinitrc" "$target_home/.xinitrc"
  link "$repo/config/rsync-home.excludes" "$config_home/rsync-home.excludes"
  link "$repo/config/postgres/config" "$config_home/postgres/config"
  link "$repo/config/OpenRGB/NRGB.orp" "$config_home/OpenRGB/NRGB.orp"
  link "$repo/config/gtk/settings.ini" "$config_home/gtk-3.0/settings.ini"
  link "$repo/config/gtk/settings.ini" "$config_home/gtk-4.0/settings.ini"
  link "$repo/config/dwm/autostart.sh" "$data_home/dwm/autostart.sh"
  link "$repo/config/dwm/autostart_blocking.sh" "$data_home/dwm/autostart_blocking.sh"

  for desktop in "$repo/applications/"*.desktop; do
    link "$desktop" "$data_home/applications/${desktop##*/}"
  done

  for script in "$repo/bin/"*; do
    link "$script" "$target_home/.local/bin/${script##*/}"
  done
}

install_user_tools() {
  local work=$work/user-tools
  local package name

  if "$dry_run"; then
    printf 'install missing pinned user tools\n'
    return
  fi

  mkdir -p "$work" "$HOME/.local/bin" "$data_home"

  if [[ ! -x $HOME/.local/bin/bemoji ]]; then
    curl -fL https://raw.githubusercontent.com/marty-oehme/bemoji/791c7748cf0236f691b1874e79ebe434469c20a9/bemoji -o "$work/bemoji"
    install -b -m 755 "$work/bemoji" "$HOME/.local/bin/bemoji"
  fi

  mkdir -p "$data_home/bemoji"
  if [[ ! -s $data_home/bemoji/emojis.txt ]]; then
    curl -fL https://www.unicode.org/Public/17.0.0/emoji/emoji-test.txt \
      -o "$work/emoji-test.txt"
    sed -n 's/^.*; fully-qualified.*# \([^[:space:]]*\) [^[:space:]]* \(.*$\)/\1 \2/p' \
      "$work/emoji-test.txt" >"$work/emojis.txt"
    [[ -s $work/emojis.txt ]]
    install -m 644 "$work/emojis.txt" "$data_home/bemoji/emojis.txt"
  fi

  if [[ ! -f $config_home/mpv/scripts/modernz.lua || ! -f $config_home/mpv/fonts/modernz-icons.ttf ]]; then
    mkdir -p "$config_home/mpv/scripts" "$config_home/mpv/fonts"
    for name in modernz.lua modernz-icons.ttf; do
      curl -fL "https://raw.githubusercontent.com/Samillion/ModernZ/579897e8c974c380caa5017dc7b27a69123c1333/$name" -o "$work/$name"
    done
    install -b -m 644 "$work/modernz.lua" "$config_home/mpv/scripts/modernz.lua"
    install -b -m 644 "$work/modernz-icons.ttf" "$config_home/mpv/fonts/modernz-icons.ttf"
  fi

  if [[ ! -x $HOME/.local/bin/resvg ]]; then
    curl -fL https://github.com/linebender/resvg/releases/download/v0.48.1/resvg-linux-x86_64.tar.gz -o "$work/resvg.tar.gz"
    tar xzf "$work/resvg.tar.gz" -C "$work"
    install -b -m 755 "$work/resvg" "$HOME/.local/bin/resvg"
  fi

  if [[ ! -r $data_home/java/google-java-format.jar ]]; then
    mkdir -p "$data_home/java"
    curl -fL https://github.com/google/google-java-format/releases/download/v1.36.1/google-java-format-1.36.1-all-deps.jar \
      -o "$work/google-java-format.jar"
    install -b -m 644 "$work/google-java-format.jar" "$data_home/java/google-java-format.jar"
  fi

  if [[ ! -x $HOME/.local/bin/google-java-format ]]; then
    printf '#!/bin/sh\nexec java -jar "%s/java/google-java-format.jar" "$@"\n' "$data_home" \
      >"$work/google-java-format"
    install -b -m 755 "$work/google-java-format" "$HOME/.local/bin/google-java-format"
  fi

  if [[ ! -x $HOME/.local/bin/sqlfluff ]]; then
    uv tool install --reinstall sqlfluff
  fi

  if [[ ! -x $HOME/.local/bin/ruff ]]; then
    uv tool install --reinstall ruff
  fi

  for package in pnpm@12 prettier; do
    if [[ ! -d $NPM_CONFIG_PREFIX/lib/node_modules/${package%@*} ]]; then
      npm install -g "$package"
    fi
  done
}

install_doom() {
  local emacs_dir=${XDG_CONFIG_HOME:-$HOME/.config}/emacs

  if "$dry_run"; then
    printf 'clone Doom Emacs and install or sync packages\n'
    return
  fi

  if [[ ! -d $emacs_dir ]]; then
    git clone --depth 1 https://github.com/doomemacs/doomemacs.git "$work/doom-emacs"
    mv -T -- "$work/doom-emacs" "$emacs_dir"
    "$emacs_dir/bin/doom" install
    return
  fi

  [[ -f ${XDG_CONFIG_HOME:-$HOME/.config}/doom/init.el ]] || {
    echo 'Doom config has no init.el yet; skipping sync.' >&2
    return 0
  }

  "$emacs_dir/bin/doom" sync
}

install_appearance() {
  local work=$work/appearance
  local name answer

  if "$dry_run"; then
    printf 'prompt for Cinder Muted GTK theme and recolored Papirus icons\n'
    return
  fi

  printf 'Install Cinder Muted GTK theme and recolored Papirus icons? [y/N] '
  if ! IFS= read -r answer; then
    answer=
  fi

  case $answer in
    y | Y | yes | YES) ;;
    *)
      printf 'skipping appearance setup\n'
      return 0
      ;;
  esac

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
    mkdir -p -- "$(dirname "$target")"
    if [[ -e $target || -L $target ]]; then
      mv -T -- "$target" "$target.backup.$stamp"
    fi
    cp -a -- "$source" "$target"
  }

  git clone --depth 1 https://github.com/aileks/cinder-muted "$work/cinder-muted"
  run "$work/cinder-muted/gtk/install.sh"

  git clone --depth 1 -b cinder-grove-folders \
    https://github.com/aileks/papirus-folders.git "$work/folders"
  mkdir -p "$work/icons" "$HOME/.local/bin"
  install -m 755 "$work/folders/papirus-folders-cg" "$work/papirus-folders-cg"
  for name in Papirus Papirus-Dark Papirus-Light; do
    cp -a -- "/usr/share/icons/$name" "$work/icons/$name"
    chmod -R u+w "$work/icons/$name"
  done
  USER_HOME="$work" XDG_CONFIG_HOME="$work/config" XDG_DATA_HOME="$work" XDG_DATA_DIRS="$work" \
    "$work/papirus-folders-cg" --theme Papirus-Dark --color orange

  for name in Papirus Papirus-Dark Papirus-Light; do
    replace "$work/icons/$name" "$data_home/icons/$name"
  done

  replace "$work/papirus-folders-cg" "$HOME/.local/bin/papirus-folders-cg"
}

setup_mime() {
  local directory mime names name browser='' target existing backup found
  local -a desktop_ids

  if "$dry_run"; then
    printf 'merge defaults from config/xdg/mimeapps.list and preserve unmanaged associations\n'
    return
  fi

  while IFS='=' read -r mime names; do
    [[ $mime != '[Default Applications]' && -n $mime ]] || continue
    IFS=';' read -ra desktop_ids <<<"$names"
    for name in "${desktop_ids[@]}"; do
      found=false
      for directory in "$data_home/applications" /usr/local/share/applications /usr/share/applications; do
        [[ ! -f $directory/$name ]] || found=true
      done
      "$found" || fail "Missing desktop entry: $name"
    done
    [[ $mime != x-scheme-handler/https ]] || browser=${desktop_ids[0]}
  done <"$repo/config/xdg/mimeapps.list"
  [[ -n $browser ]] || fail 'MIME policy must select an HTTPS browser.'

  target=$config_home/mimeapps.list
  existing=/dev/null
  [[ -f $target ]] && existing=$target

  awk '
    function remaining( key) {
      for (key in defaults)
        if (!written[key]++) print key "=" defaults[key]
    }
    FILENAME == ARGV[1] {
      if ($0 ~ /^[#;\[]/ || !index($0, "=")) next
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
  ' "$repo/config/xdg/mimeapps.list" "$existing" >"$work/mimeapps.list.merged"
  chmod 600 "$work/mimeapps.list.merged"

  if [[ -f $target ]] && cmp -s "$work/mimeapps.list.merged" "$target"; then
    rm -- "$work/mimeapps.list.merged"
  else
    if [[ -e $target || -L $target ]]; then
      backup=$target.backup.$stamp
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

setup_user() {
  export PATH="$target_home/.local/bin:$PATH"
  export NPM_CONFIG_PREFIX="$target_home/.local"

  if ! "$dry_run"; then
    install -d -m 700 "$work/runtime"
    export XDG_RUNTIME_DIR="$work/runtime"
  fi

  link_dotfiles
  install_user_tools
  install_doom
  install_appearance

  run dbus-run-session -- bash -e -c "
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark
    gsettings set org.gnome.desktop.interface cursor-theme Adwaita
    gsettings set org.gnome.desktop.interface cursor-size 24
    gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans 11'
    gsettings set org.gnome.desktop.interface monospace-font-name 'Iosevka Nerd Font 11'
    gsettings set org.gnome.desktop.interface clock-format 24h
    gsettings set org.gnome.desktop.wm.preferences button-layout ''
    gsettings set org.gnome.desktop.wm.preferences audible-bell false
    gsettings set org.gnome.desktop.sound event-sounds false
    gsettings set org.gnome.desktop.sound input-feedback-sounds false
  "

  run xdg-user-dirs-update
  setup_mime

  run fc-cache
  if "$dry_run"; then
    printf 'rebuild bat cache if its themes or bat version changed\n'
  else
    local theme_hash cache_directory
    cache_directory=$(bat --cache-dir)
    theme_hash=$({
      find -L "$config_home/bat" -type f -print0 | sort -z | xargs -0 sha256sum
      bat --version
    } | sha256sum)
    if [[ ! -f $cache_directory/dotfiles-themes || ! -f $cache_directory/themes.bin ]] \
      || [[ $(<"$cache_directory/dotfiles-themes") != "$theme_hash" ]]; then
      run bat cache --build
      printf '%s\n' "$theme_hash" >"$cache_directory/dotfiles-themes"
    fi
  fi

  install_crontab
}

main() {
  (($# <= 1)) || fail 'Usage: ./install.sh [--dry-run]'
  [[ ${1:-} == --dry-run ]] && dry_run=true

  if [[ ${DOTFILES_USER_SETUP:-} != 1 ]] && ((EUID != 0)) && ! "$dry_run"; then
    if command -v doas >/dev/null 2>&1; then
      exec doas -- "$repo/install.sh"
    elif command -v sudo >/dev/null 2>&1; then
      exec sudo -- "$repo/install.sh"
    else
      fail 'Not running as root and neither doas nor sudo is installed.'
    fi
  fi

  select_user
  void_packages=$target_home/void-packages

  if [[ ${DOTFILES_USER_SETUP:-} != 1 ]]; then
    preflight
  fi

  stamp=$(date -u +%Y%m%dT%H%M%SZ)-$$
  umask 077

  work=/tmp/dotfiles-dry-run
  if ! "$dry_run"; then
    work=$(mktemp -d -t dotfiles.XXXXXXXX)
    cleanup_directory=$work
    trap 'rm -rf -- "$cleanup_directory"' EXIT
    trap 'printf "Installation failed at line %s. Fix the error above and rerun the same command.\n" "$LINENO" >&2' ERR
  fi

  if [[ ${DOTFILES_USER_SETUP:-} == 1 ]]; then
    setup_user
    return
  fi

  run as_user git -C "$repo" submodule update --init --recursive

  if ! "$dry_run"; then
    [[ -r $repo/config/doom/init.el ]] || fail 'The Doom configuration submodule is incomplete.'
    chmod 711 "$work"
  fi

  install_system_config
  install_packages
  install_xkb
  install_suckless
  install_emacs
  build_custom_packages
  install_custom_packages
  configure_account
  configure_mdns
  configure_pipewire

  if "$dry_run"; then
    setup_user
  else
    run as_user env DOTFILES_USER_SETUP=1 "$repo/install.sh"
  fi

  enable_services

  if "$dry_run"; then
    echo 'Dry run complete; no changes made.'
  else
    echo 'Installation complete.'
  fi
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
