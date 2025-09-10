#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/icon_map.sh"

AEROSPACE_FOCUSED_MONITOR=$(aerospace list-monitors --focused 2>/dev/null | awk '{print $1}')
AEROSPACE_WORKSPACE_FOCUSED_MONITOR=$(aerospace list-workspaces --monitor focused --empty no 2>/dev/null)
AEROSPACE_EMPTY_WORKSPACES=$(aerospace list-workspaces --monitor focused --empty 2>/dev/null)

reload_workspace_icon() {
    local workspace=$1
    if [ -z "$workspace" ]; then
        return
    fi

    APPS=$(aerospace list-windows --workspace "$workspace" --format "%{app-name}" 2>/dev/null | sed '/^$/d' | uniq)
    if [ -z "$APPS" ]; then
        APPS=$(aerospace list-windows --workspace "$workspace" --format "%{app-identifier}" 2>/dev/null | sed '/^$/d' | uniq)
    fi

    ICONS=""
    if [ -n "$APPS" ]; then
        while IFS= read -r app; do
            if [ -z "$app" ]; then
                continue
            fi

            if echo "$app" | grep -q '\.'; then
                friendly="${app##*.}"
                if [ -n "$friendly" ]; then
                    app_name="$friendly"
                else
                    app_name="$app"
                fi
            else
                app_name="$app"
            fi

            __icon_map "$app_name"
            ICONS+="$icon_result "
        done <<< "$APPS"
        ICON=$(echo "$ICONS" | sed 's/ $//')
    else
        ICON="—"
    fi

    sketchybar --animate sin 10 --set space.$workspace label="$ICON"
}

update_workspace_visibility() {
    for workspace in $AEROSPACE_EMPTY_WORKSPACES; do
        if [ "$workspace" != "$AEROSPACE_FOCUSED_WORKSPACE" ]; then
            sketchybar --set space.$workspace drawing=off
        fi
    done

    for workspace in $AEROSPACE_WORKSPACE_FOCUSED_MONITOR; do
        sketchybar --set space.$workspace drawing=on display=$AEROSPACE_FOCUSED_MONITOR
    done

    if [ -n "$AEROSPACE_FOCUSED_WORKSPACE" ]; then
        sketchybar --set space.$AEROSPACE_FOCUSED_WORKSPACE drawing=on display=$AEROSPACE_FOCUSED_MONITOR
    fi
}

update_workspace_highlighting() {
    local focused_workspace=$1
    local prev_workspace=$2

    if [ -n "$focused_workspace" ]; then
        # Highlight focused workspace
        sketchybar --set space.$focused_workspace \
                   icon.color=$LABEL_COLOR \
                   label.color=$ICON_COLOR \
                   background.drawing=on \
                   background.color=$BG1
    fi

    if [ -n "$prev_workspace" ] && [ "$prev_workspace" != "$focused_workspace" ]; then
        # Un-highlight previous workspace
        sketchybar --set space.$prev_workspace \
                   icon.color=$BG4 \
                   label.color=$BG4 \
                   background.drawing=off
    fi
}

update_all_workspaces() {
    FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused 2>/dev/null)"

    for sid in $(aerospace list-workspaces --all 2>/dev/null); do
        reload_workspace_icon "$sid"

        APPS=$(aerospace list-windows --workspace "$sid" --format "%{app-name}" 2>/dev/null | sed '/^$/d')

        if [ -z "$APPS" ] && [ "$sid" != "$FOCUSED_WORKSPACE" ]; then
            sketchybar --set space.$sid drawing=off
        else
            if [ "$sid" = "$FOCUSED_WORKSPACE" ]; then
                sketchybar --set space.$sid \
                           drawing=on \
                           background.drawing=on \
                           icon.color=$LABEL_COLOR \
                           label.color=$ICON_COLOR \
                           background.color=$BG1
            else
                sketchybar --set space.$sid \
                           drawing=on \
                           background.drawing=off \
                           icon.color=$BG4 \
                           label.color=$BG4
            fi
        fi
    done
}

case "$SENDER" in
    "aerospace_workspace_change")
        AEROSPACE_FOCUSED_MONITOR=$(aerospace list-monitors --focused 2>/dev/null | awk '{print $1}')
        AEROSPACE_WORKSPACE_FOCUSED_MONITOR=$(aerospace list-workspaces --monitor focused --empty no 2>/dev/null)
        AEROSPACE_EMPTY_WORKSPACES=$(aerospace list-workspaces --monitor focused --empty 2>/dev/null)

        if [ -n "$AEROSPACE_PREV_WORKSPACE" ]; then
            reload_workspace_icon "$AEROSPACE_PREV_WORKSPACE"
        fi
        if [ -n "$AEROSPACE_FOCUSED_WORKSPACE" ]; then
            reload_workspace_icon "$AEROSPACE_FOCUSED_WORKSPACE"
        fi

        update_workspace_highlighting "$AEROSPACE_FOCUSED_WORKSPACE" "$AEROSPACE_PREV_WORKSPACE"
        update_workspace_visibility
        ;;

    "front_app_switched"|"space_windows_change"|"window_destroyed"|"window_created"|"window_focus"|"window_title_changed")
        FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused 2>/dev/null)"
        if [ -n "$FOCUSED_WORKSPACE" ]; then
            reload_workspace_icon "$FOCUSED_WORKSPACE"
        fi
        ;;

    "system_woke"|"application_launched"|"application_terminated"|"forced"|"")
        update_all_workspaces
        ;;
esac
