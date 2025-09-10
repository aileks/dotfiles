#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

sketchybar --set "$NAME" label="Checking for updates..." \
                            icon=􀐚 \
                            icon.color=$ORANGE \

COUNT=$(brew outdated 2>/dev/null | wc -l | xargs)

if [ "$COUNT" -eq 0 ]; then
    sketchybar --set "$NAME" label="􀆅" \
                                icon=􀐚 \
                                label.color=$GREEN
else
    sketchybar --set "$NAME" label="$COUNT updates" \
                                icon=􀐚 \
                                label.color=$YELLOW
fi
