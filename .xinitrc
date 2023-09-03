#!/bin/sh

# Gnome keyring
eval $(/usr/bin/gnome-keyring-daemon --start --components=gpg,pkcs11,secrets,ssh) &
export GNOME_KEYRING_CONTROL GNOME_KEYRING_PID GPG_AGENT_INFO SSH_AUTH_SOCK

# Startup
exec ~/.config/scripts/status.sh & 
exec feh --no-fehbg --bg-scale $HOME/.bg &
exec /usr/bin/lxpolkit &
exec /usr/bin/xss-lock --transfer-sleep-lock -- i3lock -i $HOME/Pictures/lockscreen.png --nofork &
exec /usr/bin/dunst > /dev/null 2>&1 &
exec /usr/bin/picom --config ~/.config/picom/picom.conf -b

# Start dwm with error logging
while true; do
  dwm 2> ~/.dwm.log
done

# Relaunch on compile
csum=""
new_csum=$(sha1sum $(which dwm))
while true
do
    if [ "$csum" != "$new_csum" ]
    then
        csum=$new_csum
        dwm
    else
        exit 0
    fi
    new_csum=$(sha1sum $(which dwm))
    sleep 0.5
done
