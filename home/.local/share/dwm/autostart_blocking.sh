#!/usr/bin/env bash

set -Eeuo pipefail

xrdb -merge ~/.Xresources
xset b off
xset dpms 0 0 900
xset r rate 250 50
setxkbmap custom
xwallpaper --zoom "$HOME/.dotfiles/wallpaper/cinder.png"
