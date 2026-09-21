#!/usr/bin/env bash

set -Eeuo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/install/lib.sh"
source "$install_dir/packages.sh"
source "$install_dir/custom-packages.sh"
source "$install_dir/system-config.sh"
source "$install_dir/suckless.sh"
source "$install_dir/emacs.sh"
source "$install_dir/stow.sh"
source "$install_dir/user-tools.sh"
source "$install_dir/user-settings.sh"

preflight() {
  local booted_root

  [[ $(. /etc/os-release 2>/dev/null && echo "$ID") == void ]] || fail 'This installer requires Void Linux.'
  command -v xbps-install >/dev/null 2>&1 || fail 'xbps-install not found.'

  booted_root=$(stat -Lc '%d:%i' /proc/1/root 2>/dev/null || true)
  if [[ -n $booted_root && $(stat -Lc '%d:%i' /) != "$booted_root" ]]; then
    fail 'The target is not the booted root.'
  fi

  [[ $repo == "$target_home/"* && -d $repo/.git ]] || fail 'Keep a Git checkout inside the desktop user home before running this installer.'
  [[ $(stat -c %u "$repo") == "$target_uid" ]] || fail "The checkout must belong to $target_user."

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

main() {
  (($# == 0)) || fail 'Usage: ./install.sh'

  if [[ ${DOTFILES_USER_SETUP:-} != 1 ]] && ((EUID != 0)); then
    command -v doas >/dev/null 2>&1 || fail 'Not running as root and doas is not installed.'
    exec doas -- "$repo/install.sh"
  fi

  common_setup "$@"

  if [[ ${DOTFILES_USER_SETUP:-} == 1 ]]; then
    setup_user_phase
    return
  fi

  preflight

  run as_user git -C "$repo" submodule update --init --recursive

  [[ -r $repo/home/.config/doom/init.el ]] || fail 'The Doom configuration submodule is incomplete.'
  chmod 711 "$work"

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
  enable_services

  run as_user env DOTFILES_USER_SETUP=1 "$repo/install.sh"

  configure_doas

  echo 'Installation complete.'
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
