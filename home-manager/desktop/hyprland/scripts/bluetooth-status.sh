#!/usr/bin/env bash
# Output JSON for Quickshell bluetooth pill

devices=$(bluetoothctl devices | awk '{print $2}')
bt_json="[]"
bt_items=""
active_name=""
active_battery=""

for dev in $devices; do
    info=$(bluetoothctl info "$dev" 2>/dev/null)
    if echo "$info" | grep -q "Connected: yes"; then
        name=$(echo "$info" | grep "Name:" | sed 's/.*Name: //')
        battery=$(echo "$info" | grep "Battery Percentage:" | sed -E 's/.*Battery Percentage:.* \(([0-9]+)\).*/\1/')
        active="true"
        if [ -z "$active_name" ]; then
            active_name="$name"
            if [ -n "$battery" ]; then
                active_battery="${battery}%"
            else
                active_battery=""
            fi
        fi
    else
        name=$(echo "$info" | grep "Name:" | sed 's/.*Name: //')
        active="false"
        battery=""
    fi
    
    # Escape quotes
    name="${name//\"/\\\"}"
    
    item="{\"name\": \"$name\", \"mac\": \"$dev\", \"active\": $active, \"battery\": \"$battery\"}"
    if [ -z "$bt_items" ]; then
        bt_items="$item"
    else
        bt_items="$bt_items, $item"
    fi
done

bt_json="[$bt_items]"

# Power state
power_state=$(bluetoothctl show | grep "Powered: yes")
status="Off"
if [ -n "$power_state" ]; then
    if [ -n "$active_name" ]; then
        status="Connected"
    else
        status="On"
    fi
else
    # If BT is off, return empty array
    bt_json="[]"
fi

if [ -z "$active_name" ]; then
    active_name="Bluetooth"
    active_battery="Disconnected"
fi

cat <<EOF
{
  "devices": $bt_json,
  "status": "$status",
  "active_name": "$active_name",
  "active_battery": "$active_battery"
}
EOF
