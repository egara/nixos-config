#!/usr/bin/env bash

# Script for Maintenace operations in NixOS
# -----------------------------------------
#
# @author: Eloy García Almadén
# @email: eloy.garcia.pca@gmail.com
# ------------------------------------------

items="Update\nClean"
output=$(echo -e $items | walker --dmenu -H)

if [[ "$output" == "Update" ]]; then
  kitty --hold sh -c "~/.config/hypr/nixos-update.sh"
elif [[ "$output" == "Clean" ]]; then
  kitty --hold sh -c "~/.config/hypr/nixos-clean.sh"
else
  echo "Select a maintenace process"
fi
