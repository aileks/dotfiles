install_suckless() {
  local name
  for name in dwm st dmenu slock dwmblocks; do
    run make -C "$repo/desktop/$name" clean install
  done
  if [[ ! -d $target_home/.terminfo ]]; then
    run as_user tic -sx "$repo/desktop/st/st.info"
  fi
}
