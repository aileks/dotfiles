#!/bin/bash

eval $(/usr/bin/gnome-keyring-daemon --start --components=gpg,pkcs11,secrets,ssh)
export GNOME_KEYRING_CONTROL GNOME_KEYRING_PID GPG_AGENT_INFO SSH_AUTH_SOCK
export _JAVA_AWT_WM_NONREPARENTING=1
export wmname "LG3D"

sh -c "/home/aileks/.config/dwm/scripts/status.sh" & 
/home/aileks/.fehbg &
/usr/bin/lxpolkit &
/usr/bin/xscreensaver --no-splash &
/usr/bin/dunst > /dev/null 2>&1 &
