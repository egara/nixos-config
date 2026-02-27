#!/usr/bin/env bash

# Sicos Screensaver
# Uses hypridle for reliable input detection.

START_TIME_FILE="/tmp/sicos-screensaver.start"

start_screensaver() {
    # Prevent multiple instances by checking for running kitty instances labeled as screensaver class
    if pgrep -f "kitty --class screensaver" > /dev/null; then
        exit 0
    fi

    date +%s > "$START_TIME_FILE"

    # Get active workspace for each monitor to launch kitty there
    # Format: "MONITOR_NAME WORKSPACE_ID"
    while read -r MON WS_ID; do
        # Launch kitty on the specific workspace using [workspace ID] rule
        hyprctl dispatch exec "[workspace $WS_ID] kitty --class screensaver --start-as=fullscreen bash -c 'trap \"kill 0\" EXIT; (while true; do tte -i ~/.config/sicos/screensaver/sicos-art.txt --frame-rate 120 --canvas-width 0 --canvas-height 0 --reuse-canvas --anchor-canvas c --anchor-text c --random-effect --no-eol --no-restore-cursor; done) & read -n 1 -s'"
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

    # Only stop if it's been running for more than 2 seconds
    if [ "$ELAPSED" -gt 2 ]; then
        pkill -f "kitty --class screensaver"
        rm -f "$START_TIME_FILE"
    else
        # If < 2s, we might be in a "ghost" resume event caused by window creation focus changes.
        # But it might also be a real user trying to wake immediately.

        INITIAL_POS=$(hyprctl cursorpos)

        # Poll for 2 seconds to catch immediate wake-ups
        for i in {1..20}; do
            CURRENT_POS=$(hyprctl cursorpos)
            if [ "$INITIAL_POS" != "$CURRENT_POS" ]; then
                pkill -f "kitty --class screensaver"
                rm -f "$START_TIME_FILE"
                exit 0
            fi
            sleep 0.1
        done

        # If no movement detected after 2s, it was likely a ghost event.
        # The screensaver stays up, BUT hypridle now thinks the system is "Active" (because of the ghost event).
        # We must spawn a background watcher to manually kill the screensaver when the user *actually* moves the mouse later.
        (
            INITIAL_POS_BG=$(hyprctl cursorpos)
            while pgrep -f "kitty --class screensaver" > /dev/null; do
                CURRENT_POS_BG=$(hyprctl cursorpos)
                if [ "$INITIAL_POS_BG" != "$CURRENT_POS_BG" ]; then
                    pkill -f "kitty --class screensaver"
                    rm -f "$START_TIME_FILE"
                    exit 0
                fi
                sleep 0.5
            done
        ) & disown
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
