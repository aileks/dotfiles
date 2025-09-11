#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

if [ "$SENDER" = "front_app_switched" ]; then
    APP_NAME="$INFO"
else
    APP_NAME=$(aerospace list-windows --focused --format "%{app-name}" 2>/dev/null)
fi

if [ -z "$APP_NAME" ]; then
    sketchybar --set "$NAME" drawing=off
    return
fi

sketchybar --set "$NAME" icon="􀢌" \
                         icon.font="SF Pro:Bold:14" \
                         icon.color=$FG2 \
                         label="$APP_NAME" \
                         background.color=$BG1 \
                         drawing=on
