source "${BASH_SOURCE[0]%/*}/lib.sh"

install_stow() {
  local -a anchors=(
    "$config_home"
    "$config_home/mpv"
    "$config_home/qt6ct"
    "$config_home/OpenRGB"
    "$config_home/postgres"
    "$config_home/gtk-3.0"
    "$config_home/gtk-4.0"
    "$target_home/.local/bin"
    "$data_home/applications"
    "$data_home/dwm"
  )

  command -v stow >/dev/null 2>&1 || fail 'stow is not installed (xbps-install stow)'

  run mkdir -p -- "${anchors[@]}"
  run stow --dir="$repo" --target="$target_home" home
  run stow --dir="$repo" --target="$target_home" --no-folding partial
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  common_setup "$@"
  install_stow
fi
