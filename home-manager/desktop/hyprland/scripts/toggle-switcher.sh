#!/usr/bin/env bash
# Toggle the Quickshell window switcher overlay via a FIFO.
# This script is invoked by Hyprland on ALT + Tab.

FIFO="/tmp/sicos-switcher-fifo"

# Create the FIFO if it doesn't exist
[ -p "$FIFO" ] || mkfifo "$FIFO" 2>/dev/null

# Resolve the currently focused monitor so Quickshell renders the
# overlay only on that screen instead of mirroring it on all of them.
FOCUSED=$(hyprctl -j monitors 2>/dev/null | jq -r '.[] | select(.focused == true) | .name')

# Send toggle command in the background so we don't block
# if Quickshell isn't currently listening.
(printf 'toggle %s\n' "$FOCUSED" > "$FIFO") &
