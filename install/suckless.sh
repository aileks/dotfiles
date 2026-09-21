source "${BASH_SOURCE[0]%/*}/lib.sh"

install_suckless() {
  local name
  for name in dwm st dmenu slock dwmblocks; do
    run make -C "$repo/config/$name" clean install
  done
  if [[ ! -d $target_home/.terminfo ]]; then
    run as_user tic -sx "$repo/config/st/st.info"
  fi
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  common_setup "$@"
  install_suckless
fi
