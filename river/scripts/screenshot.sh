#!/usr/bin/env bash

SAVE_DIR="${HOME}/Pictures/Screenshots"
FILENAME="Capture_$(date +'%Y-%m-%d at %H:%M:%S')"
FILE_PATH="${SAVE_DIR}/${FILENAME}"

if [ ! -d "$SAVE_DIR" ]; then
	mkdir -p "$SAVE_DIR"
fi

usage() {
	echo "Usage: $(basename "$0") [options]"
	echo "Options:"
	echo "  -f, --full        Take a screenshot of the entire screen."
	echo "  -s, --selection     Select a region to screenshot (default)."
	echo "  -o, --output        Select the active output/monitor to screenshot."
	echo "  -c, --copy          Copy the screenshot to the clipboard instead of saving."
	echo "  -b, --both          Save the screenshot to a file AND copy it to the clipboard."
	echo "  -h, --help          Show this help message."
	exit 1
}

MODE="selection" # 'selection', 'full', or 'output'
TARGET="file"    # 'file', 'copy', or 'both'

while [ $# -gt 0 ]; do
	case "$1" in
	-f | --full)
		MODE="full"
		shift
		;;
	-s | --selection)
		MODE="selection"
		shift
		;;
	-o | --output)
		MODE="output"
		shift
		;;
	-c | --copy)
		TARGET="copy"
		shift
		;;
	-b | --both)
		TARGET="both"
		shift
		;;
	-h | --help)
		usage
		;;
	*)
		echo "Unknown option: $1"
		usage
		;;
	esac
done

case "$MODE" in
full)
	GEOMETRY=""
	;;
selection)
	GEOMETRY=$(slurp)
	;;
output)
	GEOMETRY=$(slurp -o)
	;;
esac

if [ "$MODE" != "full" ] && [ -z "$GEOMETRY" ]; then
	notify-send "Screenshot Cancelled" "No area selected."
	exit 1
fi

if [[ -n "$GEOMETRY" ]]; then
	GRIM_ARGS+=(-g "$GEOMETRY")
fi

case "$TARGET" in
file)
	grim "${GRIM_ARGS[@]}" "$FILE_PATH"
	notify-send "Screenshot Saved" "Saved to <b>${FILE_PATH}</b>"
	;;
copy)
	grim "${GRIM_ARGS[@]}" - | wl-copy
	notify-send "Screenshot Copied" "Copied to clipboard."
	;;
both)
	grim "${GRIM_ARGS[@]}" - | tee "$FILE_PATH" | wl-copy
	notify-send "Screenshot Saved & Copied" "Saved to <b>${FILE_PATH}</b> and copied."
	;;
esac

exit 0
