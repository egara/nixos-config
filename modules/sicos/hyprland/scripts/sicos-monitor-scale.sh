#!/usr/bin/env bash

# sicos-monitor-scale.sh - Manage and persist Hyprland monitor scaling for SicOS
# Usage:
#   sicos-monitor-scale.sh --list
#   sicos-monitor-scale.sh --set <MONITOR_NAME> <SCALE_VALUE>

set -euo pipefail

KANSHI_REPO_CONFIG="$HOME/Zero/nixos-config/home-manager/desktop/hyprland/programs/kanshi/config"
KANSHI_MODULE_CONFIG="$HOME/Zero/nixos-config/modules/sicos/hyprland/config-files/kanshi/config"
KANSHI_LOCAL_CONFIG="$HOME/.config/kanshi/config"

# Ensure ~/.config/kanshi/config is writable or symlinked to repo config
sync_local_kanshi_config() {
    if [ -L "$KANSHI_LOCAL_CONFIG" ]; then
        local target
        target=$(readlink -f "$KANSHI_LOCAL_CONFIG" || true)
        if [[ "$target" == *"/nix/store/"* ]]; then
            rm -f "$KANSHI_LOCAL_CONFIG"
            ln -s "$KANSHI_REPO_CONFIG" "$KANSHI_LOCAL_CONFIG"
        fi
    elif [ ! -e "$KANSHI_LOCAL_CONFIG" ]; then
        mkdir -p "$(dirname "$KANSHI_LOCAL_CONFIG")"
        ln -s "$KANSHI_REPO_CONFIG" "$KANSHI_LOCAL_CONFIG"
    fi
}

# List connected monitors in JSON format for QuickShell
list_monitors() {
    hyprctl monitors -j | jq -c '[.[] | {
        id: .id,
        name: .name,
        description: .description,
        make: .make,
        model: .model,
        width: .width,
        height: .height,
        refreshRate: .refreshRate,
        scale: .scale,
        focused: .focused
    }]'
}

# Hyprland requires scales where the resolution divides cleanly into whole logical pixels (in 1/120 steps).
clean_scale() {
    local req_scale="$1"
    local width="$2"
    local height="$3"
    awk -v scale="$req_scale" -v width="$width" -v height="$height" '
        function gcd(a, b, t) { while (b) { t = a % b; a = b; b = t } return a }
        BEGIN {
            g = gcd(width * 120, height * 120)
            k = int(scale * 120 + 0.5)
            if (k > g) k = g
            while (g % k != 0) k++
            printf "%g\n", k / 120
        }'
}

# Apply scale live via hyprctl
apply_live_scale() {
    local monitor_name="$1"
    local requested_scale="$2"

    local monitor_info
    monitor_info=$(hyprctl monitors -j | jq -e -c ".[] | select(.name == \"$monitor_name\")" 2>/dev/null || true)

    if [ -z "$monitor_info" ]; then
        echo "Error: Monitor '$monitor_name' not found." >&2
        return 1
    fi

    local width height refresh_rate position_x position_y
    width=$(echo "$monitor_info" | jq -r '.width')
    height=$(echo "$monitor_info" | jq -r '.height')
    refresh_rate=$(echo "$monitor_info" | jq -r '.refreshRate')
    position_x=$(echo "$monitor_info" | jq -r '.x')
    position_y=$(echo "$monitor_info" | jq -r '.y')

    local new_scale
    new_scale=$(clean_scale "$requested_scale" "$width" "$height")

    hyprctl eval "hl.monitor({ output = \"${monitor_name}\", mode = \"${width}x${height}@${refresh_rate}\", position = \"${position_x}x${position_y}\", scale = ${new_scale} })" >/dev/null 2>&1 || \
    hyprctl eval "hl.monitor({ output = \"${monitor_name}\", mode = \"preferred\", position = \"auto\", scale = ${new_scale} })" >/dev/null 2>&1
}

# Update scale in Kanshi configuration file
update_kanshi_config() {
    local config_file="$1"
    local monitor_name="$2"
    local new_scale="$3"

    [ -f "$config_file" ] || return 1
    [ -w "$config_file" ] || return 1

    local monitor_info
    monitor_info=$(hyprctl monitors -j | jq -e -c ".[] | select(.name == \"$monitor_name\")" 2>/dev/null || true)

    local description make model
    description=$(echo "$monitor_info" | jq -r '.description // ""')
    make=$(echo "$monitor_info" | jq -r '.make // ""')
    model=$(echo "$monitor_info" | jq -r '.model // ""')

    python3 - "$config_file" "$monitor_name" "$description" "$make" "$model" "$new_scale" << 'EOF'
import sys, re, socket

config_path = sys.argv[1]
mon_name = sys.argv[2]
mon_desc = sys.argv[3]
mon_make = sys.argv[4]
mon_model = sys.argv[5]
new_scale = float(sys.argv[6])
hostname = socket.gethostname().lower()

def check_match(line):
    if not line.strip().startswith("output "):
        return False
    
    match = re.search(r'^output\s+["\']?([^"\'+]+?)["\']?\s+', line.strip())
    if not match:
        parts = line.strip().split()
        if len(parts) >= 2:
            criteria = parts[1]
        else:
            return False
    else:
        criteria = match.group(1).strip()
    
    clean_criteria = re.sub(r'(\s+Unknown|\*)+$', '', criteria, flags=re.IGNORECASE).strip()
    clean_desc = re.sub(r'(\s+Unknown|\*)+$', '', mon_desc, flags=re.IGNORECASE).strip()

    if criteria == mon_name or clean_criteria == mon_name:
        return True
    if clean_criteria and clean_desc and (clean_criteria == clean_desc):
        return True
    if clean_criteria and clean_desc and (clean_criteria in clean_desc or clean_desc in clean_criteria):
        return True

    if mon_make and mon_model:
        make_model = f"{mon_make} {mon_model}".strip()
        if clean_criteria in make_model or make_model in clean_criteria:
            return True

    return False

with open(config_path, 'r') as f:
    lines = f.readlines()

updated = False
new_lines = []
in_matching_profile = False

# Pass 1: Try matching inside profiles corresponding to this host
for line in lines:
    stripped = line.strip()
    if stripped.startswith("profile "):
        prof_name = stripped.split()[1].lower()
        in_matching_profile = hostname in prof_name
    elif stripped == "}":
        in_matching_profile = False
    elif in_matching_profile and stripped.startswith("output "):
        if check_match(line):
            if "scale " in line:
                line = re.sub(r'(scale\s+)[0-9.]+', r'\g<1>' + f"{new_scale:.6f}".rstrip('0').rstrip('.'), line)
                updated = True
            elif "enable" in line:
                line = line.rstrip('\n') + f" scale {new_scale:.6f}".rstrip('0').rstrip('.') + "\n"
                updated = True

    new_lines.append(line)

# Fallback Pass 2: If no profile matched hostname, update any output line matching criteria
if not updated:
    new_lines = []
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("output "):
            if check_match(line):
                if "scale " in line:
                    line = re.sub(r'(scale\s+)[0-9.]+', r'\g<1>' + f"{new_scale:.6f}".rstrip('0').rstrip('.'), line)
                    updated = True
                elif "enable" in line:
                    line = line.rstrip('\n') + f" scale {new_scale:.6f}".rstrip('0').rstrip('.') + "\n"
                    updated = True
        new_lines.append(line)

if updated:
    with open(config_path, 'w') as f:
        f.writelines(new_lines)
    sys.exit(0)
else:
    sys.exit(1)
EOF
}

case "${1:-}" in
    --list)
        list_monitors
        ;;
    --set)
        if [ "$#" -lt 3 ]; then
            echo "Usage: $0 --set <MONITOR_NAME> <SCALE_VALUE>" >&2
            exit 1
        fi
        MONITOR_NAME="$2"
        SCALE_VALUE="$3"

        sync_local_kanshi_config

        # 1. Apply requested scale live via Hyprland IPC
        apply_live_scale "$MONITOR_NAME" "$SCALE_VALUE"

        # 2. Query Hyprland IPC for the actual accepted scale (Hyprland rounds invalid scales to nearest valid fractional divisor)
        ACTUAL_SCALE=$(hyprctl monitors -j | jq -r ".[] | select(.name == \"$MONITOR_NAME\") | .scale // empty" 2>/dev/null || true)
        PERSIST_SCALE="${ACTUAL_SCALE:-$SCALE_VALUE}"

        # 3. Update Kanshi config files on disk with actual applied scale
        update_kanshi_config "$KANSHI_REPO_CONFIG" "$MONITOR_NAME" "$PERSIST_SCALE" || true
        update_kanshi_config "$KANSHI_MODULE_CONFIG" "$MONITOR_NAME" "$PERSIST_SCALE" || true
        update_kanshi_config "$KANSHI_LOCAL_CONFIG" "$MONITOR_NAME" "$SCALE_VALUE" || true

        # 4. If Kanshi daemon is active, trigger kanshictl reload so Kanshi loads the actual applied scale into memory
        if pgrep -x kanshi >/dev/null 2>&1 || systemctl --user is-active --quiet kanshi.service 2>/dev/null; then
            kanshictl reload 2>/dev/null || systemctl --user reload kanshi.service 2>/dev/null || true
        fi

        echo "Applied scale $PERSIST_SCALE (requested: $SCALE_VALUE) for $MONITOR_NAME."
        ;;
    *)
        echo "Usage: $0 {--list|--set <MONITOR_NAME> <SCALE_VALUE>}" >&2
        exit 1
        ;;
esac
