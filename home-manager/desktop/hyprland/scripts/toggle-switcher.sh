#!/usr/bin/env bash
# Toggle the Quickshell window switcher overlay via a FIFO.
# This script is invoked by Hyprland on ALT + Tab.

FIFO="/tmp/sicos-switcher-fifo"

# Create the FIFO if it doesn't exist
[ -p "$FIFO" ] || mkfifo "$FIFO" 2>/dev/null

# Send toggle command in the background so we don't block
# if Quickshell isn't currently listening.
(printf 'toggle\n' > "$FIFO") &
