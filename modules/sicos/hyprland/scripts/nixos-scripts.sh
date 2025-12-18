#!/usr/bin/env bash

# Script for Maintenace operations in NixOS
# -----------------------------------------
#
# @author: Eloy García Almadén
# @email: eloy.garcia.pca@gmail.com
# ------------------------------------------

items="\u00A0\u00A0\u00A0\u00A0Clean"

output=$(echo -e $items | walker --dmenu -H)

if [[ "$output" == *"Clean"* ]]; then
  kitty --hold sh -c "~/.config/hypr/nixos-clean.sh"

# Add some more here
# elif [[ "$output" == *"Update"* ]]; then

else
  echo "Select an option"
fi
