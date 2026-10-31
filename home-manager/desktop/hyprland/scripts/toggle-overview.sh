#!/usr/bin/env bash
# Toggle, open, or close the Quickshell workspace overview (Exposé) overlay via a FIFO.
# This script is invoked by Hyprland keybindings or touchpad gestures.
# Usage:
#   toggle-overview.sh        # Toggles overview on the active screen
#   toggle-overview.sh open   # Opens overview on the active screen
#   toggle-overview.sh close  # Closes overview

ACTION="${1:-toggle}"
FIFO="/tmp/sicos-overview-fifo"

# Create the FIFO if it doesn't exist
[ -p "$FIFO" ] || mkfifo "$FIFO" 2>/dev/null

# Resolve the currently focused monitor so Quickshell renders the
# overlay only on that screen instead of mirroring it on all of them.
FOCUSED=$(hyprctl -j monitors 2>/dev/null | jq -r '.[] | select(.focused == true) | .name')

# Send command in the background so we don't block
# if Quickshell isn't currently listening.
(printf '%s %s\n' "$ACTION" "$FOCUSED" > "$FIFO") &
