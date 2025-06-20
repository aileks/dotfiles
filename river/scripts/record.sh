#!/usr/bin/env bash

VIDEOS_DIR="$HOME/Videos/Recordings"

if [ ! -d "$VIDEOS_DIR" ]; then
	mkdir -p "$VIDEOS_DIR"
fi

PID_FILE="/tmp/wf-recorder.pid"

if [ -f "$PID_FILE" ] && pgrep -F "$PID_FILE" >/dev/null; then
	pkill -F "$PID_FILE" -INT
	rm "$PID_FILE"
	notify-send "Screen recording stopped."
else
	GEOMETRY=$(slurp)

	if [ -z "$GEOMETRY" ]; then
		exit 0
	fi

	wf-recorder --audio -g "$GEOMETRY" -f "$VIDEOS_DIR/$(date +'%Y-%m-%d_%H-%M-%S').mp4" &
	echo $! >"$PID_FILE"
	notify-send "Screen recording started."
fi
