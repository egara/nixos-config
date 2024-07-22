#!/usr/bin/env bash

# Script for disabling the laptop screen in Hyrpland
# --------------------------------------------------
#
# @author: Eloy García Almadén
# @email: eloy.garcia.pca@gmail.com
# ------------------------------------------

# Run hyprctl monitors command and store the output
output=$(hyprctl monitors)

# Check if the output contains "HDMI-"
if [[ "$output" == *"HDMI-"* ]]; then
  if [[ $1 == "open" ]]; then
    hyprctl keyword monitor "eDP-1,1920x1080,1920x0,1"
    echo 'Lip is opened. Enabling laptop screen' | systemd-cat -p info
  else
    hyprctl keyword monitor "eDP-1,disable"
    echo 'Lip is closed. Disabling laptop screen' | systemd-cat -p info
  fi
else
    echo "no!"
fi
