#!/bin/bash

# Gnome keyring
eval $(/usr/bin/gnome-keyring-daemon --start --components=gpg,pkcs11,secrets,ssh) &
export GNOME_KEYRING_CONTROL GNOME_KEYRING_PID GPG_AGENT_INFO SSH_AUTH_SOCK

# Startup
[[ -f ~/.Xresources ]] && xrdb -merge -I$HOME ~/.Xresources &
exec $HOME/.config/scripts/startup.sh &
exec $HOME/.config/scripts/status.sh & 

# Start dwm with error logging and allow relaunch hotkey
while type dwm >/dev/null ; do dwm 2> ~/.dwm.log && continue || break ; done
