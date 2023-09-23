#!/bin/sh

# Gnome keyring
eval $(/usr/bin/gnome-keyring-daemon --start --components=gpg,pkcs11,secrets,ssh) &
export GNOME_KEYRING_CONTROL GNOME_KEYRING_PID GPG_AGENT_INFO SSH_AUTH_SOCK

# Startup
[[ -f ~/.Xresources ]] && xrdb -merge -I$HOME ~/.Xresources &
exec ~/.config/scripts/status.sh & 
exec feh --no-fehbg --bg-scale $HOME/.bg.png &
exec /usr/bin/lxpolkit &
exec /usr/bin/xss-lock --transfer-sleep-lock -- i3lock -i $HOME/Pictures/lockscreen.png --nofork &
exec /usr/bin/dunst > /dev/null 2>&1 &
exec /usr/bin/picom --config $HOME/.config/picom/picom.conf -b &
exec setxkbmap -option numpad:mac &
exec flameshot &
exec xmodmap $HOME/.Xmodmap &

# Start dwm with error logging and allow relaunch hotkey
while type dwm >/dev/null ; do dwm 2> ~/.dwm.log && continue || break ; done
