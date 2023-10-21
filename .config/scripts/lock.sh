#!/bin/sh

alpha='dd'
background='#232634'
selection='#414559'
comment='#626880'

yellow='#e5c890'
orange='#ef9f76'
red='#e78284'
magenta='#f4b8e4'
blue='#8caaee'
cyan='#85c1dc' 
green='#a6d189'

i3lock \
  --insidever-color=$selection$alpha \
  --insidewrong-color=$selection$alpha \
  --inside-color=$selection$alpha \
  --ringver-color=$green$alpha \
  --ringwrong-color=$red$alpha \
  --ringver-color=$green$alpha \
  --ringwrong-color=$red$alpha \
  --ring-color=$blue$alpha \
  --line-uses-ring \
  --keyhl-color=$magenta$alpha \
  --bshl-color=$orange$alpha \
  --separator-color=$selection$alpha \
  --verif-color=$green \
  --wrong-color=$red \
  --layout-color=$blue \
  --date-color=$blue \
  --time-color=$blue \
  --screen 1 \
  --blur 1 \
  --clock \
  --indicator \
  --time-str="%H:%M:%S" \
  --date-str="%A %B %e, %Y" \
  --verif-text="Checking..." \
  --wrong-text="Wrong password" \
  --noinput="No Input" \
  --lock-text="Locking..." \
  --lockfailed="Lock Failed" \
  --radius=120 \
  --ring-width=10 \
  --pass-media-keys \
  --pass-screen-keys \
  --pass-volume-keys \
  --time-font="FantasqueSansM Nerd Font" \
  --date-font="FantasqueSansM Nerd Font" \
  --layout-font="FantasqueSansM Nerd Font" \
  --verif-font="FantasqueSansM Nerd Font" \
  --wrong-font="FantasqueSansM Nerd Font"
