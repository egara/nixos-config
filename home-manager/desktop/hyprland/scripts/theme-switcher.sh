#!/usr/bin/env bash

# Script for switching theme on SicOS
# -----------------------------------
#
# @author: Eloy García Almadén
# @email: eloy.garcia.pca@gmail.com
# -------------------------------------

# Check if a theme argument is provided
if [[ "$1" != "light" && "$1" != "dark" ]]; then
  echo "Usage: $0 [light|dark]"
  exit 1
fi

# Getting theme from the first argument
THEME="$1"
# Getting hostname
HOST="$(hostname)"
# Getting DESKTOP environment
DESKTOP="$(echo $XDG_CURRENT_DESKTOP)"
# Define the configuration path
CONFIG_PATH="$HOME/Zero/nixos-config"

# Renaming DESKTOP environment to match flake output names
if [ "$DESKTOP" = "Hyprland" ] || [ "$DESKTOP" = "hyprland" ]; then
  DESKTOP="hyprland"
elif [ "$DESKTOP" = "KDE" ] || [ "$DESKTOP" = "kde" ] || [ "$DESKTOP" = "plasma" ]; then
  DESKTOP="plasma"
fi

echo "Searching for the theming configuration file in $CONFIG_PATH..."

# Find the file containing the 'themeMode' setting, excluding the README and the script itself.
# -r: recursive search
# -l: print only file names of matching files
# --exclude: pattern for files to exclude
FILE_TO_EDIT=$(grep -r -l --exclude="README.md" --exclude="theme-switcher.sh" 'themeMode = "' "$CONFIG_PATH")

# Error handling if no file is found
if [ -z "$FILE_TO_EDIT" ]; then
    echo "Error: Could not find any configuration file with 'themeMode'."
    exit 1
fi

# Error handling if multiple files are found
if [ $(echo "$FILE_TO_EDIT" | wc -l) -gt 1 ]; then
    echo "Error: Found multiple configuration files with 'themeMode'. Aborting to prevent unintended changes."
    echo "Files found:"
    echo "$FILE_TO_EDIT"
    exit 1
fi

echo "Found configuration file: $FILE_TO_EDIT"
echo "Setting SicOS theme to '$THEME'..."

# Use sed to replace the theme value in the identified file.
# This command finds the line starting with optional whitespace followed by 'themeMode = "'
# and replaces only the value inside the quotes, preserving indentation and the attribute path.
sed -i "s/\(themeMode = \s*\"\).*\(\"\s*;\)/\1$THEME\2/" "$FILE_TO_EDIT"

echo "Configuration file updated. Rebuilding the system..."

# Navigate to the flake's directory
pushd "$CONFIG_PATH"

# Rebuild the NixOS system with the new theme
sudo nixos-rebuild switch --flake .#$HOST-$DESKTOP

# Restart Waybar to apply theme changes
echo "Restarting Waybar to apply new theme..."
pkill waybar
sleep 1
uwsm app -- waybar &

echo "Theme changed successfully to '$THEME'!"
