#!/usr/bin/env bash

# Set variables
OPTIONS="Reboot system\nPower-off system\nSuspend system\nLogout"
LAUNCHER="rofi -dmenu -i -p rofi-power:"
USE_LOCKER="false"
LOCKER="i3lock"

option=`echo -e $OPTIONS | $LAUNCHER | awk '{print $1}' | tr -d '\r\n'`
if [ ${#option} -gt 0 ]
then
    case $option in
      Exit)
        eval $1
        ;;
      Reboot)
        systemctl reboot
        ;;
      Power-off)
        systemctl poweroff
        ;;
      Suspend)
        $($USE_LOCKER) && "$LOCKER"; systemctl suspend
        ;;
      Logout)
        $($USE_LOCKER) && "$LOCKER"; pkill dwm
        ;;
      *)
        ;;
    esac
fi
