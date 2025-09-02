#!/usr/bin/env bash

# Script for Maintenace operations in NixOS
# -----------------------------------------
#
# @author: Eloy García Almadén
# @email: eloy.garcia.pca@gmail.com
# ------------------------------------------

items="󰚰\u00A0\u00A0\u00A0\u00A0Update\n\u00A0\u00A0\u00A0\u00A0Clean\n󰱦\u00A0\u00A0\u00A0\u00A0Extranet\n\u00A0\u00A0\u00A0\u00A0Eclipse\n\u00A0\u00A0\u00A0\u00A0Hibernate"

output=$(echo -e $items | walker --dmenu -H)

if [[ "$output" == *"Update"* ]]; then
  kitty --hold sh -c "~/.config/hypr/nixos-update.sh"
elif [[ "$output" == *"Clean"* ]]; then
  kitty --hold sh -c "~/.config/hypr/nixos-clean.sh"
elif [[ "$output" == *"Extranet"* ]]; then
  kitty --hold sh -c "~/scripts/nixos/extranet.sh"
elif [[ "$output" == *"Eclipse"* ]]; then
  . ~/scripts/nixos/eclipse.sh
elif [[ "$output" == *"Hibernate"* ]]; then
  kitty --hold sh -c "distrobox enter arch -- ~/distrobox/arch/programs/eclipse-2023-12/eclipse"
else
  echo "Select an option"
fi
