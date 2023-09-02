#!/bin/sh

# Gnome keyring
eval $(/usr/bin/gnome-keyring-daemon --start --components=gpg,pkcs11,secrets,ssh) &
export GNOME_KEYRING_CONTROL GNOME_KEYRING_PID GPG_AGENT_INFO SSH_AUTH_SOCK

# Env variables
export _JAVA_AWT_WM_NONREPARENTING=1
export QT_QPT_PLATFORMTHEME=qt5ct

# Startup
exec ~/.config/scripts/status.sh & 
exec feh --no-fehbg --bg-scale $HOME/.bg &
exec /usr/bin/lxpolkit &
exec /usr/bin/xss-lock --transfer-sleep-lock -- i3lock -i $HOME/Pictures/lockscreen.png --nofork &
exec /usr/bin/dunst > /dev/null 2>&1 &

# Start dwm with error logging
while true; do
  dwm 2> ~/.dwm.log
done
