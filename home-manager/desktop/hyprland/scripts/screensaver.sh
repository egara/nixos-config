#!/usr/bin/env bash

# Sicos Screensaver - Time-guarded version
# Uses hypridle for reliable input detection.

LOCKFILE="/tmp/sicos-screensaver.lock"
START_TIME_FILE="/tmp/sicos-screensaver.start"

start_screensaver() {
    # Prevent multiple instances
    if [ -f "$LOCKFILE" ]; then
        PID=$(cat "$LOCKFILE")
        if kill -0 "$PID" 2>/dev/null; then exit 0; fi
    fi
    echo $$ > "$LOCKFILE"
    date +%s > "$START_TIME_FILE"

    # Launch kitty
    kitty --class screensaver --start-as=fullscreen bash -c "
    while true; do
      tte -i ~/.config/sicos/screensaver/sicos-art.txt \
        --frame-rate 120 --canvas-width 0 --canvas-height 0 --reuse-canvas --anchor-canvas c --anchor-text c \
        --random-effect \
        --no-eol --no-restore-cursor
    done"
    
    # Cleanup when kitty is closed manually
    rm -f "$LOCKFILE" "$START_TIME_FILE"
}

stop_screensaver() {
    if [ ! -f "$START_TIME_FILE" ]; then exit 0; fi
    
    START_TIME=$(cat "$START_TIME_FILE")
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))

    # Only stop if it's been running for more than 2 seconds
    # This avoids the "auto-close" bug when the window opens
    if [ "$ELAPSED" -gt 2 ]; then
        pkill -f "kitty --class screensaver"
        rm -f "$LOCKFILE" "$START_TIME_FILE"
    fi
}

case "$1" in
    stop)
        stop_screensaver
        ;;
    start|*)
        start_screensaver
        ;;
esac