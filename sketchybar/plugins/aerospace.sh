#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/icon_map.sh"

update_spaces() {
    FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused)"

    for sid in $(aerospace list-workspaces --all); do
        APPS=$(aerospace list-windows --workspace "$sid" --format "%{app-name}")

        if [ -z "$APPS" ] && [ "$sid" != "$FOCUSED_WORKSPACE" ]; then
            sketchybar --set space.$sid drawing=off
        else
            ICONS=""
            while IFS= read -r app; do
                if [ -n "$app" ]; then
                    __icon_map "$app"
                    ICONS+="$icon_result "
                fi
            done <<< "$APPS"
            ICON=$(echo "$ICONS" | sed 's/ $//')

            if [ "$sid" = "$FOCUSED_WORKSPACE" ] && [ -z "$APPS" ]; then
                ICON="—"
            fi

            if [ "$sid" = "$FOCUSED_WORKSPACE" ]; then
                sketchybar --set space.$sid drawing=on \
                                            background.drawing=on \
                                            icon="$sid" \
                                            label="$ICON" \
                                            icon.color=$LABEL_COLOR \
                                            label.color=$ICON_COLOR
            else
                sketchybar --set space.$sid drawing=on \
                                            background.drawing=off \
                                            icon="$sid" \
                                            label="$ICON" \
                                            icon.color=$BG4 \
                                            label.color=$BG4
            fi
        fi
    done
}

case "$SENDER" in
    "aerospace_workspace_change"|"front_app_switched"|"space_windows_change"|"forced")
        update_spaces
        ;;
    *)
        update_spaces
        ;;
esac
