#!/usr/bin/env bash
# Network stats script for Quickshell
# Generates JSON with speed, ping, IP, etc.

IFACE=$(ip route get 8.8.8.8 2>/dev/null | grep -Po '(?<=dev )(\S+)' | head -n 1)

if [ -z "$IFACE" ]; then
    echo '{"ping":"-","loss":"-","rx_speed":"0 B/s","tx_speed":"0 B/s","rx_total":"0 B","tx_total":"0 B","ip":"-","gateway":"-"}'
    exit 0
fi

IP=$(ip -4 addr show $IFACE 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
GW=$(ip route show default 2>/dev/null | grep -oP '(?<=via\s)\d+(\.\d+){3}' | head -n 1)

format_bytes() {
    local bytes=$1
    if [ -z "$bytes" ]; then echo "0 B"; return; fi
    if [ $bytes -lt 1024 ]; then echo "${bytes} B"
    elif [ $bytes -lt 1048576 ]; then echo "$((bytes/1024)) KB"
    elif [ $bytes -lt 1073741824 ]; then echo "$((bytes/1048576)) MB"
    else echo "$((bytes/1073741824)) GB"
    fi
}

rx_current=$(cat /sys/class/net/$IFACE/statistics/rx_bytes 2>/dev/null || echo 0)
tx_current=$(cat /sys/class/net/$IFACE/statistics/tx_bytes 2>/dev/null || echo 0)
time_current=$(date +%s%3N) # ms

TMP_FILE="/tmp/sicos_net_stats_${IFACE}"
rx_speed="0 B/s"
tx_speed="0 B/s"
ping_prev="-"
loss_prev="-"
time_prev_ping=0

if [ -f "$TMP_FILE" ]; then
    # source the file
    . "$TMP_FILE" 2>/dev/null
    
    time_diff=$((time_current - time_prev))
    if [ "$time_diff" -gt 0 ]; then
        rx_diff=$((rx_current - rx_prev))
        tx_diff=$((tx_current - tx_prev))
        
        # avoid negative diffs (e.g. on interface reset)
        if [ "$rx_diff" -lt 0 ]; then rx_diff=0; fi
        if [ "$tx_diff" -lt 0 ]; then tx_diff=0; fi
        
        rx_bps=$(( (rx_diff * 1000) / time_diff ))
        tx_bps=$(( (tx_diff * 1000) / time_diff ))
        
        rx_speed="$(format_bytes $rx_bps)/s"
        tx_speed="$(format_bytes $tx_bps)/s"
    fi
fi

# Ping every 5 seconds to avoid freezing the UI for 1s on every poll
time_since_ping=$((time_current - time_prev_ping))
if [ "$time_since_ping" -gt 5000 ]; then
    ping_out=$(ping -c 1 -W 1 1.1.1.1 2>/dev/null)
    if [ $? -eq 0 ]; then
        ping_val=$(echo "$ping_out" | grep 'time=' | sed -E 's/.*time=([0-9.]+) ms.*/\1/')
        ping_prev="${ping_val%.*} ms"
        loss_prev="0%"
    else
        ping_prev="-"
        loss_prev="100%"
    fi
    time_prev_ping=$time_current
fi

# Save state securely
cat <<STATE > "$TMP_FILE"
rx_prev=$rx_current
tx_prev=$tx_current
time_prev=$time_current
ping_prev="$ping_prev"
loss_prev="$loss_prev"
time_prev_ping=$time_prev_ping
STATE

rx_total=$(format_bytes $rx_current)
tx_total=$(format_bytes $tx_current)

cat <<EOF
{
  "ping": "$ping_prev",
  "loss": "$loss_prev",
  "rx_speed": "$rx_speed",
  "tx_speed": "$tx_speed",
  "rx_total": "$rx_total",
  "tx_total": "$tx_total",
  "ip": "${IP:--}",
  "gateway": "${GW:--}"
}
EOF
