#!/usr/bin/env bash

set -Eeuo pipefail

dwmblocks &
pipewire &

/usr/libexec/polkit-gnome-authentication-agent-1 &
dunst &
blueman-applet &
playerctld daemon &
udiskie --tray &
gnome-keyring-daemon --start --components=secrets,pkcs11 &
xss-lock --transfer-sleep-lock -- lock-session &
openrgb --noautoconnect -p NRGB &
localsend &
/opt/Bitwarden/bitwarden &
emacs --daemon &
xautolock -time 10 -locker lock-session -notify 30 -notifier 'notify-send -t 2000 -a xautolock "Locking in 30 seconds"' &
