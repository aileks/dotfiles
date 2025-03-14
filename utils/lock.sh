#!/usr/bin/env bash

alpha='dd'
background='#191724'
selection='#26233a'
comment='#908caa'
muted='#6e6a86'
gold='#f6c177'
rose='#ebbcba'
love='#eb6f92'
iris='#c4a7e7'
pine='#31748f'
foam='#9ccfd8'

i3lock \
  --insidever-color=$muted$alpha \
  --insidewrong-color=$rose$alpha \
  --inside-color=$selection$alpha \
  --ringver-color=$foam$alpha \
  --ringwrong-color=$love$alpha \
  --ring-color=$pine$alpha \
  --line-uses-ring \
  --keyhl-color=$iris$alpha \
  --bshl-color=$gold$alpha \
  --separator-color=$selection$alpha \
  --verif-color=$foam \
  --wrong-color=$love \
  --modif-color=$love \
  --layout-color=$comment \
  --date-color=$comment \
  --time-color=$comment \
  --screen 1 \
  --blur 1 \
  --clock \
  --indicator \
  --time-str="%H:%M:%S" \
  --date-str="%A, %B %e %Y" \
  --verif-text="Checking..." \
  --wrong-text="Wrong pswd" \
  --noinput="No Input" \
  --lock-text="Locking..." \
  --lockfailed="Lock Failed" \
  --radius=120 \
  --ring-width=10 \
  --pass-media-keys \
  --pass-screen-keys \
  --pass-volume-keys \
  --time-font="BerkeleyMono Nerd Font" \
  --date-font="BerkeleyMono Nerd Font" \
  --layout-font="BerkeleyMono Nerd Font" \
  --verif-font="BerkeleyMono Nerd Font" \
  --wrong-font="BerkeleyMono Nerd Font" \

