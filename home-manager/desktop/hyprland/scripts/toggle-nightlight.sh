#!/usr/bin/env bash

# Toggle hyprsunset for Night Mode
# If it's running, kill it. If it's not, start it with 4000K temperature.

if pgrep -x hyprsunset > /dev/null; then
    pkill -x hyprsunset
    # Send a notification
    notify-send -a "SicOS" -i weather-clear-symbolic -t 2000 "Night Mode" "Disabled"
else
    # Run in background detached
    setsid uwsm app -- hyprsunset -t 4000 >/dev/null 2>&1 &
    notify-send -a "SicOS" -i weather-clear-night-symbolic -t 2000 "Night Mode" "Enabled (4000K)"
fi
