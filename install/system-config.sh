source "${BASH_SOURCE[0]%/*}/lib.sh"

install_system_config() {
  local source relative mode

  while IFS= read -r -d '' source; do
    relative=${source#"$repo/"}
    mode=644
    case $relative in
      etc/doas.conf) mode=400 ;;
    esac
    install_system_file "$source" "/$relative" "$mode"
  done < <(find "$repo/etc" -type f -print0 | sort -z)
}

install_xkb() {
  local xkb_root=/usr/share/X11/xkb
  [[ ! -L $xkb_root ]] || xkb_root=$(readlink -f "$xkb_root")
  install_system_file "$repo/config/xkb/symbols/custom" "$xkb_root/symbols/custom"
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

configure_doas() {
  if [[ -e /etc/xbps.d/99-ignore-sudo.conf ]]; then
    return
  fi

  if "$dry_run"; then
    printf 'ignore sudo in xbps and remove it, leaving doas as the elevation tool\n'
    return
  fi

  install_missing opendoas

  if xbps-query sudo >/dev/null 2>&1; then
    run xbps-remove -y sudo
  fi

  printf '%s\n' 'ignorepkg=sudo' >"$work/ignore-sudo.conf"
  install_system_file "$work/ignore-sudo.conf" /etc/xbps.d/99-ignore-sudo.conf

  doas -C /etc/doas.conf || fail 'doas rejected /etc/doas.conf.'
  if command -v sudo >/dev/null 2>&1; then
    fail 'sudo is still installed.'
  fi
  printf 'doas is the only elevation tool\n'
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  common_setup "$@"
  install_system_config
  install_xkb
  configure_account
  configure_mdns
  configure_pipewire
  enable_services
  configure_doas
fi
