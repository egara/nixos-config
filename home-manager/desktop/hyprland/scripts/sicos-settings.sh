#!/usr/bin/env bash

# SicOS main menu
# -----------------------------------------
#
# @author: Eloy García Almadén
# @email: eloy.garcia.pca@gmail.com
# ------------------------------------------

items="󱓟\u00A0\u00A0\u00A0\u00A0 Applications\n⏻\u00A0\u00A0\u00A0\u00A0 Power\n󰚰\u00A0\u00A0\u00A0\u00A0 Update\n\u00A0\u00A0\u00A0\u00A0 Clean\n󱕅\u00A0\u00A0\u00A0\u00A0 Screensaver\n󰔎\u00A0\u00A0\u00A0\u00A0 Themes\n󰸉\u00A0\u00A0\u00A0\u00A0 Wallpapers\n\u00A0\u00A0\u00A0\u00A0Hyprland Keybindings\n󰱦\u00A0\u00A0\u00A0\u00A0 Extranet\n\u00A0\u00A0\u00A0\u00A0 Eclipse\n\u00A0\u00A0\u00A0\u00A0 Hibernate"

output=$(echo -e $items | walker --dmenu -H -n -N)

if [[ "$output" == *"Applications"* ]]; then
    uwsm app -- walker
elif [[ "$output" == *"Power"* ]]; then
    wlogout --protocol layer-shell
elif [[ "$output" == *"Update"* ]]; then
    kitty --hold sh -c "~/.config/sicos/scripts/nixos-update.sh"
elif [[ "$output" == *"Clean"* ]]; then
    kitty --hold sh -c "~/.config/sicos/scripts/nixos-clean.sh"
elif [[ "$output" == *"Screensaver"* ]]; then
    . ~/.config/sicos/scripts/screensaver.sh
elif [[ "$output" == *"Themes"* ]]; then
    # sicosthemes is located in ~/.config/elephant/menus/sicos_themes.lua script file
    exec walker -m menus:sicosthemes -H -n -N --width 800 --minheight 400
elif [[ "$output" == *"Wallpapers"* ]]; then
    # sicoswallpapers is located in ~/.config/elephant/menus/sicos_wallpapers.lua script file
    exec walker -m menus:sicoswallpapers -H --width 800 --minheight 400
elif [[ "$output" == *"Hyprland"* ]]; then
    . ~/.config/sicos/scripts/show-hyprland-keybindings.sh
elif [[ "$output" == *"Extranet"* ]]; then
    kitty --hold sh -c "~/scripts/nixos/extranet.sh"
elif [[ "$output" == *"Eclipse"* ]]; then
    . ~/scripts/nixos/eclipse.sh
elif [[ "$output" == *"Hibernate"* ]]; then
    kitty --hold sh -c "distrobox enter arch -- ~/distrobox/arch/programs/eclipse-2023-12/eclipse"
else
    echo "Select an option"
fi
