source "${BASH_SOURCE[0]%/*}/lib.sh"

custom_packages=(
  zig
  zls
  localsend
  onlyoffice-desktopeditors
  bitwarden-desktop
)

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

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  common_setup "$@"
  build_custom_packages
  install_custom_packages
fi
