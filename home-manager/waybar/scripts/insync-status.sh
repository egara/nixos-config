#!/usr/bin/env sh

# --- Configuration for NixOS ---
# Path to the Insync logs database (standard Linux location)
INS_LOGS_DB="$HOME/.config/Insync/logs.db"
# KEYWORDS: The definitive list of log phrases indicating active syncing (Upload or Download)
# 'download' for active download; 'AddCloudGDItem' and 'ADD' for active upload processing.
SYNCING_KEYWORDS="AddCloudGDItem|ADD|download|processing|queue"

# The path to 'find' and 'wc' are usually correct on NixOS, 
# but if Waybar is running in a very minimal shell, you might need to 
# ensure coreutils and findutils are in the Waybar environment.

# --- Status Checks ---

# Check if Insync is running (using pgrep -x for exact match)
# The pgrep utility must be available in the Waybar environment (part of procps).
if ! pgrep -x insync > /dev/null; then
    echo '{"text": "", "tooltip": "Insync is not running", "class": "error"}'
    exit 0
fi

# Check for active syncing using log messages
# Query the last 50 log messages and check if any contain the SYNCING_KEYWORDS.
# This is the most reliable method, as it uses Insync's internal status records.
SYNCING_COUNT=$(sqlite3 "$INS_LOGS_DB" "SELECT message FROM logs ORDER BY created DESC LIMIT 25;" \
    | grep -E -i "$SYNCING_KEYWORDS" \
    | wc -l)
                
# --- Process and Output Status ---

ICON="󰅟"
CLASS="synced"
TOOLTIP_TEXT="Insync: All files synced"

if [ "$SYNCING_COUNT" -gt 0 ]; then
    # If the count is > 0, it means an active sync file was found.
    ICON="󰘿" # Cloud with spinning arrows
    CLASS="syncing"
    TOOLTIP_TEXT="Insync is currently syncing..."
fi

# --- Output the result as JSON for Waybar ---
# Using echo with the icon character directly in the JSON string.
# We ensure the script uses the necessary utilities and quotes correctly.

JSON_OUTPUT='{"text": "'"$ICON"'", "tooltip": "'"$TOOLTIP_TEXT"'", "class": "'"$CLASS"'"}'

# Use echo and ensure the shell is robust enough to handle the UTF-8 characters.
# The shebang '#!/usr/bin/env sh' at the top of the file helps here.
echo "$JSON_OUTPUT"