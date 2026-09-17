#!/usr/bin/env bash
set -u

uid=$UID
config_home=${XDG_CONFIG_HOME:-$HOME/.config}
data_home=${XDG_DATA_HOME:-$HOME/.local/share}

dbus-update-activation-environment DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE

xset b off

pgrep -u "$uid" -x pipewire >/dev/null || gentoo-pipewire-launcher &
pgrep -u "$uid" -x gnome-keyring-d >/dev/null || gnome-keyring-daemon --start --components=secrets,pkcs11 &
pgrep -u "$uid" -f polkit-gnome-authentication >/dev/null || /usr/libexec/polkit-gnome-authentication-agent-1 &
pgrep -u "$uid" -x xwallpaper >/dev/null || xwallpaper --zoom "$data_home/backgrounds/fantasy-woods.jpg" &
pgrep -u "$uid" -x picom >/dev/null || picom &
pgrep -u "$uid" -x dunst >/dev/null || dunst &
pgrep -u "$uid" -x playerctld >/dev/null || playerctld daemon &
pgrep -u "$uid" -x udiskie >/dev/null || udiskie --tray &
pgrep -u "$uid" -x blueman-applet >/dev/null || blueman-applet &
pgrep -u "$uid" -f clipmenud >/dev/null || CM_SELECTIONS=clipboard clipmenud &
pgrep -u "$uid" -x wezterm-mux-ser >/dev/null || wezterm-mux-server --config-file "$config_home/wezterm/wezterm.lua" &
pgrep -u "$uid" -x emacs >/dev/null || emacs --daemon &
pgrep -u "$uid" -x xss-lock >/dev/null || xss-lock --transfer-sleep-lock -- lock-session &
pgrep -u "$uid" -x xautolock >/dev/null || {
  xautolock -time 10 -locker lock-session -notify 30 -notifier 'notify-send -t 2000 -a xautolock "Locking in 30 seconds"' &
}
xset dpms 0 0 900
pgrep -u "$uid" -x bitwarden-app >/dev/null || /opt/Bitwarden/bitwarden &
pgrep -u "$uid" -x localsend >/dev/null || localsend &
pgrep -u "$uid" -x openrgb >/dev/null || openrgb --noautoconnect -p NRGB &
