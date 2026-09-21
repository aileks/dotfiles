#!/usr/bin/env bash

set -Eeuo pipefail

export PATH="$HOME/.local/bin:$PATH"
export QT_QPA_PLATFORM=wayland
export QT_QPA_PLATFORMTHEME=qt5ct
export XDG_CURRENT_DESKTOP=dwm
export XDG_SESSION_TYPE=x11
export XCURSOR_THEME=Adwaita
export XCURSOR_SIZE=24
export BEMOJI_PICKER_CMD='dmenu -i -c -l 8 -p Emoji -S'
export BEMOJI_CLIP_CMD=xclip
export CM_LAUNCHER=dmenu
export CM_DIR="${XDG_RUNTIME_DIR:-/run/user/$UID}/clipmenu"
export CM_MAX_CLIPS=20
export LIBVA_DRIVER_NAME=nvidia
export NVD_BACKEND=direct
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export MOZ_DISABLE_RDD_SANDBOX=1

exec dbus-run-session -- dwm
