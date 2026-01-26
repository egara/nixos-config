#!/usr/bin/env bash

# --- Path to your Hyprland configuration ---
CONFIG_FILE="$HOME/.config/hypr/hyprland.conf"

# --- Check if the file exists ---
if [[ ! -f "$CONFIG_FILE" ]]; then
    notify-send "Error" "Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# 1. Extract and clean the binds
# 2. Use AWK to format with tabs (\t)
# 3. Use 'sort' to group shortcuts alphabetically
grep -E '^bind[a-z]*\s*=' "$CONFIG_FILE" | \
    sed -e 's/^[^=]*=[[:space:]]*//' \
        -e 's/,[[:space:]]*exec.*//' \
        -e 's/^,[[:space:]]*//' \
        -e 's/,[[:space:]]*$//' | \
    sed 's/\$mainMod/SUPER/g' | \
    awk -F, '{
        # Trim whitespace
        for (i=1; i<=NF; i++) gsub(/^[ \t]+|[ \t]+$/, "", $i);

        if (NF >= 2) {
            shortcut = $1 " + " $2;
            desc = ""; 
            for(i=3; i<=NF; i++) desc = desc $i (i==NF ? "" : ", ");
            gsub(/^[ \t]+|[ \t]+$/, "", desc);
            if (desc == "") desc = "System Action";

            # Using \t (Tabs) for flexible alignment
            printf "%s \t➜  %s\n", shortcut, desc
        } 
        else if (NF == 1 && $1 != "") {
            printf "%s \t➜  Special Key\n", $1
        }
    }' | walker --dmenu
