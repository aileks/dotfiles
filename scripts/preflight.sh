#!/usr/bin/env bash

set -u

failed=0
for cmd in mango mmsg waybar wmenu wezterm wezterm-mux-server yazi qutebrowser \
  swaylock swayidle swaybg wlopm dunst gammastep wl-copy wl-paste cliphist \
  playerctl playerctld nm-applet networkmanager_dmenu udiskie wpctl wiremix \
  grim slurp loginctl elogind-inhibit dbus-run-session dbus-update-activation-environment \
  gentoo-pipewire-launcher podman pinentry-gnome3 bw keyctl xkbcli; do
  command -v "$cmd" >/dev/null || {
    echo "MISSING: $cmd"
    failed=1
  }
done

for font in 'Iosevka Nerd Font' 'IosevkaTerm Nerd Font' 'Adwaita Sans'; do
  family=$(fc-match -f '%{family}' "$font")
  [[ $family == *"$font"* ]] || {
    echo "FONT: $font resolved to $family"
    failed=1
  }
done

[[ -x /usr/libexec/polkit-gnome-authentication-agent-1 ]] || {
  echo 'Missing PolicyKit agent'
  failed=1
}

XKB_CONFIG_EXTRA_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/xkb" xkbcli compile-keymap --layout aileks >/dev/null || failed=1
exit "$failed"
