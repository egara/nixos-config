#!/usr/bin/env bash

# Sicos Screensaver - Time-guarded version
# Uses hypridle for reliable input detection.

START_TIME_FILE="/tmp/sicos-screensaver.start"

start_screensaver() {
    # Prevent multiple instances by checking for running processes directly
    if pgrep -f "kitty --class screensaver" > /dev/null; then
        exit 0
    fi
    
    date +%s > "$START_TIME_FILE"

    # Get active workspace for each monitor to launch kitty there
    # Format: "MONITOR_NAME WORKSPACE_ID"
    while read -r MON WS_ID; do
        # Launch kitty on the specific workspace using [workspace ID] rule
        hyprctl dispatch exec "[workspace $WS_ID] kitty --class screensaver --start-as=fullscreen bash -c 'while true; do tte -i ~/.config/sicos/screensaver/sicos-art.txt --frame-rate 120 --canvas-width 0 --canvas-height 0 --reuse-canvas --anchor-canvas c --anchor-text c --random-effect --no-eol --no-restore-cursor; done'"
    done < <(hyprctl monitors -j | jq -r '.[] | "\(.name) \(.activeWorkspace.id)"')

    # Wait for kitty processes to start
    sleep 0.5

    # Wait until all screensaver windows are closed
    while pgrep -f "kitty --class screensaver" > /dev/null; do
        sleep 1
    done

    # Cleanup when kitty is closed manually
    rm -f "$START_TIME_FILE"
}

stop_screensaver() {
    if [ ! -f "$START_TIME_FILE" ]; then
        # If no start time file, check if process exists and kill immediately (fallback)
        if pgrep -f "kitty --class screensaver" > /dev/null; then
             pkill -f "kitty --class screensaver"
        fi
        exit 0
    fi
    
    START_TIME=$(cat "$START_TIME_FILE")
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))

    # If less than 2 seconds have passed, wait the remaining time
    # instead of ignoring the stop request. This fixes the issue where
    # early user activity fails to close the screensaver.
    if [ "$ELAPSED" -lt 2 ]; then
        sleep "$((2 - ELAPSED))"
    fi

    pkill -f "kitty --class screensaver"
    rm -f "$START_TIME_FILE"
}

case "$1" in
    stop)
        stop_screensaver
        ;;
    start|*)
        start_screensaver
        ;;
esac
