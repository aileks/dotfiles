install_stow() {
  command -v stow >/dev/null 2>&1 || fail 'stow is not installed (xbps-install stow)'

  run mkdir -p -- "$target_home/.local/bin" "$data_home/applications" "$data_home/dwm"
  run stow --dir="$repo" --target="$target_home" --no-folding partial
  run stow --dir="$repo" --target="$target_home" home
}
