#!/usr/bin/env bash
# Output JSON for Quickshell network pill

eth_json="[]"
wifi_json="[]"
active_name=""
active_signal=""
active_type=""

# Get ethernet devices
eth_dev=$(nmcli -t -c no dev status | awk -F':' '$2=="ethernet" && $3=="connected" {print $1; exit}')
if [ -n "$eth_dev" ]; then
    con_name=$(nmcli -t -c no dev status | awk -F':' -v dev="$eth_dev" '$1==dev {print $4; exit}')
    eth_json="[{\"name\": \"$eth_dev ($con_name)\", \"active\": true}]"
    active_name="$con_name"
    active_signal="Connected"
    active_type="ethernet"
else
    eth_dev_down=$(nmcli -t -c no dev status | awk -F':' '$2=="ethernet" {print $1; exit}')
    if [ -n "$eth_dev_down" ]; then
        eth_json="[{\"name\": \"$eth_dev_down\", \"active\": false}]"
    fi
fi

# Get wifi networks
# Format: IN-USE:SSID:SIGNAL
wifi_list=$( (nmcli -t -c no -f IN-USE,SSID,SIGNAL dev wifi list | grep '^\*'; nmcli -t -c no -f IN-USE,SSID,SIGNAL dev wifi list | grep '^ ') | grep -v '^:' | grep -v '^--' )
wifi_items=""
declare -A seen
while IFS=':' read -r inuse ssid signal rest; do
    if [ -z "$ssid" ]; then continue; fi
    
    if [ "$inuse" = "*" ]; then
        active="true"
        seen["$ssid"]=1
        if [ -z "$active_name" ]; then # Prefer wifi if both connected (or maybe ethernet? Ethernet is usually preferred, but wifi is what they showed)
            active_name="$ssid"
            active_signal="${signal}%"
            active_type="wifi"
        fi
    else
        active="false"
        if [ "${seen[$ssid]}" = "1" ]; then
            continue
        fi
        seen["$ssid"]=1
    fi
    
    item="{\"name\": \"$ssid\", \"active\": $active, \"signal\": \"$signal\"}"
    if [ -z "$wifi_items" ]; then
        wifi_items="$item"
    else
        wifi_items="$wifi_items, $item"
    fi
done <<< "$wifi_list"

wifi_json="[$wifi_items]"

# Quick toggle states
eth_quick="Disconnected"
if [ "$eth_json" != "[]" ] && echo "$eth_json" | grep -q 'true'; then
    eth_quick="Connected"
fi

wifi_quick="Disconnected"
if echo "$wifi_json" | grep -q 'true'; then
    wifi_quick="Connected"
fi

# Fallback if none active
if [ -z "$active_name" ]; then
    active_name="Network"
    active_signal="Disconnected"
    active_type="none"
fi

cat <<JSON
{
  "ethernet": $eth_json,
  "wifi": $wifi_json,
  "eth_status": "$eth_quick",
  "wifi_status": "$wifi_quick",
  "active_name": "$active_name",
  "active_signal": "$active_signal",
  "active_type": "$active_type"
}
JSON
