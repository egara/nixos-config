#!/usr/bin/env bash

# Script for Maintenace operations in NixOS
# -----------------------------------------
#
# @author: Eloy García Almadén
# @email: eloy.garcia.pca@gmail.com
# ------------------------------------------

items="\u00A0\u00A0\u00A0\u00A0Clean\n󰔎\u00A0\u00A0\u00A0\u00A0Themes\n󰸉\u00A0\u00A0\u00A0\u00A0Wallpapers"

output=$(echo -e $items | walker --dmenu -H -n -N)

if [[ "$output" == *"Clean"* ]]; then
  kitty --hold sh -c "~/.config/sicos/scripts/nixos-clean.sh"

# Add some more here
# elif [[ "$output" == *"Update"* ]]; then
elif [[ "$output" == *"Themes"* ]]; then
    # sicosthemes is located in ~/.config/elephant/menus/sicos_themes.lua script file
    exec walker -m menus:sicosthemes -H -n -N --width 800 --minheight 400
elif [[ "$output" == *"Wallpapers"* ]]; then
    # sicoswallpapers is located in ~/.config/elephant/menus/sicos_wallpapers.lua script file
    exec walker -m menus:sicoswallpapers -H --width 800 --minheight 400
else
  echo "Select an option"
fi
