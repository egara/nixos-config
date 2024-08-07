#!/usr/bin/env bash

# Script for disabling the laptop screen in Hyrpland
# --------------------------------------------------
#
# @author: Eloy García Almadén
# @email: eloy.garcia.pca@gmail.com
# ------------------------------------------

# Running hyprctl monitors command and store the output
output=$(hyprctl monitors)

# Checking if the output contains "HDMI-"
if [[ "$output" == *"HDMI-"* ]]; then
  if [[ $1 == "open" ]]; then
    hyprctl keyword monitor "eDP-1,1920x1080,1920x0,1"
    echo "Lip is opened. Enabling laptop screen" | systemd-cat -p info
  else
    hyprctl keyword monitor "eDP-1,disable"
    echo "Lip is closed. Disabling laptop screen" | systemd-cat -p info
  fi

  # Checking if waybar has crashed
  echo "Checking if waybar has crashed" | systemd-cat -p info
  sleep 3
  waybarActive=$(ps -A | grep waybar | wc -l)

  if [ "$waybarActive" -gt 0 ]
  then 
    echo "waybar is OK. waybarActive = $waybarActive. Skipping..." | systemd-cat -p info
  else
    echo "waybar has crashed. waybarActive = $waybarActive. Enabling it again" | systemd-cat -p info
    waybar &
  fi  
else
    echo "No external monitor HDMI-* has been detected. Type hyprctl monitors to see active monitors and modify this script." | systemd-cat -p info
fi
