#!/usr/bin/env bash

# Script for changing the wallpaper randomly
# ------------------------------------------
#
# @author: Eloy García Almadén
# @email: eloy.garcia.pca@gmail.com
# ------------------------------------------

# Selecting a wallpaper randomly
WALLPAPER=$(ls /home/egarcia/Insync/eloy.garcia.pca@gmail.com/Google\ Drive/Wallpapers | shuf -n 1)

# Changing the wallpaper
swww img /home/egarcia/Insync/eloy.garcia.pca@gmail.com/Google\ Drive/Wallpapers/${WALLPAPER}
