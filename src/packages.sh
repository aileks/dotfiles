packages=(
  linux-firmware NetworkManager network-manager-applet dnsmasq dbus-elogind elogind polkit-elogind pciutils usbutils openssh opendoas
  avahi nss-mdns cups bluez blueman gst-plugins-base1 gst-plugins-good1 gst-plugins-bad1 gst-plugins-ugly1 xtools gst-libav
  docker docker-compose 7zip tree bat eza psmisc fd fzf git jq shfmt ripgrep sqlite stow trash-cli unzip gsettings-desktop-schemas
  wget xdotool rsync zip zoxide nvme-cli btop fastfetch curl github-cli xorg-server xinit xauth xorg-apps xf86-input-libinput
  slop xkeyboard-config alsa-pipewire pipewire libspa-bluetooth wireplumber-elogind pulseaudio-utils j4-dmenu-desktop maim xclip
  xss-lock clipmenu xwallpaper xautolock fontconfig fontconfig-devel nnn zathura zathura-pdf-mupdf zathura-cb zathura-djvu uv
  mpv mpv-mpris gvfs pcmanfm lxappearance dunst libnotify playerctl wiremix cava qalculate-gtk file-roller ncdu2 imv udiskie
  tumbler xdg-utils xdg-user-dirs polkit-gnome xdg-desktop-portal-gtk ffmpeg6 ffmpegthumbnailer alsa-utils ddcutil libva-utils
  nvtop cronie tesseract-ocr tesseract-ocr-eng hunspell hunspell-en keyutils pinentry dconf Vulkan-Tools gnome-keyring qt6ct
  papirus-icon-theme adwaita-icon-theme adwaita-fonts noto-fonts-ttf openrgb noto-fonts-cjk noto-fonts-emoji Signal-Desktop
  freetype-devel imlib2-devel openjdk21 pkg-config libX11-devel libXcursor-devel libXext-devel libXft-devel cmake libXinerama-devel
  libXrandr-devel libXrender-devel libxcb-devel libxcrypt-devel xcb-util-devel clang gcc gdb make bubblewrap ImageMagick neovim
  libvterm tree-sitter-cli libgccjit-devel jansson-devel tree-sitter-devel gtk+3-devel cairo-devel harfbuzz-devel giflib-devel
  libjpeg-turbo-devel libpng-devel librsvg-devel libwebp-devel libxml2-devel gnutls-devel texinfo autoconf automake libXpm-devel
  ncurses-devel gpu-screen-recorder doasedit firefox dotool python3-gobject python3-cairo
  qutebrowser python3-adblock python3-readability-lxml yt-dlp nodejs
)

install_packages() {
  install_missing void-repo-nonfree

  if [[ $gpu_vendor == nvidia ]]; then
    packages+=(nvidia nvidia-vaapi-driver)
  fi

  install_missing "${packages[@]}"
}
