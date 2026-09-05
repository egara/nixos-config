#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Script for switching theme on SicOS
# -----------------------------------
#
# @author: Eloy García Almadén
# @email: eloy.garcia.pca@gmail.com
# -------------------------------------

# Check for arguments
THEME=""
SCHEME=""
FONT_SIZE=""
GET_SIZE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --get-size|--get-font-size)
      GET_SIZE=true
      shift
      ;;
    --size|--font-size)
      FONT_SIZE="$2"
      shift 2
      ;;
    --theme)
      THEME="$2"
      shift 2
      ;;
    --scheme)
      SCHEME="$2"
      shift 2
      ;;
    light|dark)
      THEME="$1"
      shift
      if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
        if [[ "$1" =~ ^[0-9]+$ ]]; then
          FONT_SIZE="$1"
        else
          SCHEME="$1"
        fi
        shift
      fi
      if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
        if [[ "$1" =~ ^[0-9]+$ ]]; then
          FONT_SIZE="$1"
          shift
        fi
      fi
      ;;
    [0-9]*)
      FONT_SIZE="$1"
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [light|dark] [scheme (optional)] [font_size (optional)]"
      echo "       $0 --size <font_size>"
      echo "       $0 --theme [light|dark] [--scheme <scheme>] [--size <font_size>]"
      echo "       $0 --get-size"
      echo "Available schemes: catppuccin-mocha, equilibrium-light, everforest, gruvbox-dark, gruvbox-light-soft"
      exit 0
      ;;
    *)
      echo "Unknown option or argument: $1"
      echo "Usage: $0 [light|dark] [scheme (optional)] [font_size (optional)]"
      echo "       $0 --size <font_size>"
      echo "       $0 --get-size"
      exit 1
      ;;
  esac
done

# Define the configuration path
CONFIG_PATH="$HOME/Zero/nixos-config"
# Define the SicOS wallpapers path
WALLPAPERS_PATH="$HOME/.config/sicos/wallpapers"

# Find the file containing the 'themeMode' setting, excluding the README and the script itself.
# -r: recursive search
# -l: print only file names of matching files
# --exclude: pattern for files to exclude
FILE_TO_EDIT=$(grep -r -l --exclude="README.md" --exclude="theme-switcher.sh" 'themeMode = "' "$CONFIG_PATH" 2>/dev/null || true)

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

# Handle --get-size query
if [ "$GET_SIZE" = true ]; then
  if grep -q 'themeFontSize\s*=' "$FILE_TO_EDIT"; then
    SIZE_VAL=$(grep -E 'themeFontSize\s*=' "$FILE_TO_EDIT" | head -n 1 | sed -E 's/.*themeFontSize\s*=\s*([0-9]+)\s*;.*/\1/')
    echo "$SIZE_VAL"
  else
    echo "10"
  fi
  exit 0
fi

# Ensure at least one setting to change was requested
if [ -z "$THEME" ] && [ -z "$SCHEME" ] && [ -z "$FONT_SIZE" ]; then
  echo "Usage: $0 [light|dark] [scheme (optional)] [font_size (optional)]"
  echo "       $0 --size <font_size>"
  echo "       $0 --theme [light|dark] [--scheme <scheme>] [--size <font_size>]"
  echo "       $0 --get-size"
  echo "Available schemes: catppuccin-mocha, equilibrium-light, everforest, gruvbox-dark, gruvbox-light-soft"
  exit 1
fi

# Getting hostname
HOST="$(hostname)"
# Getting DESKTOP environment
DESKTOP="$(echo $XDG_CURRENT_DESKTOP)"

# Renaming DESKTOP environment to match flake output names
if [ "$DESKTOP" = "Hyprland" ] || [ "$DESKTOP" = "hyprland" ]; then
  DESKTOP="hyprland"
elif [ "$DESKTOP" = "KDE" ] || [ "$DESKTOP" = "kde" ] || [ "$DESKTOP" = "plasma" ]; then
  DESKTOP="plasma"
fi

echo "   ___ _       ___  ___  "
echo "  / __(_)__   / _ \/ __| "
echo "  \__ \ / _| | (_) \__ \ "
echo "  |___/_\__|  \___/|___/ "
echo "    Theme Switcher       "
echo "                         "
echo "Steps to perform:"
echo " 1. Locate configuration file"
echo " 2. Update theming in configuration"
echo " 3. Rebuild NixOS system"
echo " 4. Restart UI services (QuickShell, Waybar, SwayNC, Walker)"
echo " 5. Update wallpaper"
echo "                         "

echo "Searching for the theming configuration file in $CONFIG_PATH..."
echo "Found configuration file: $FILE_TO_EDIT"

# 1. Update theme mode if requested
if [ -n "$THEME" ]; then
  echo "Setting SicOS theme to '$THEME'..."
  # Use sed to replace the theme value in the identified file.
  # This command finds the line starting with optional whitespace followed by 'themeMode = "'
  # and replaces only the value inside the quotes, preserving indentation and the attribute path.
  sed -i 's/\(themeMode = \s*"\).*\("\s*;\)/\1'"$THEME"'\2/' "$FILE_TO_EDIT"
fi

# 2. Update scheme if requested
if [ -n "$SCHEME" ]; then
  echo "Setting SicOS scheme to '$SCHEME'..."
  # Check if themeScheme exists in the file
  if grep -q 'themeScheme = "' "$FILE_TO_EDIT"; then
    sed -i 's/\(themeScheme = \s*"\).*\("\s*;\)/\1'"$SCHEME"'\2/' "$FILE_TO_EDIT"
  else
    echo "Warning: 'themeScheme' variable not found in $FILE_TO_EDIT. Skipping scheme update."
  fi
fi

# 3. Update font size if requested
if [ -n "$FONT_SIZE" ]; then
  echo "Setting SicOS font size to '${FONT_SIZE}pt'..."
  # Check if themeFontSize exists in the configuration file
  if grep -q 'themeFontSize\s*=' "$FILE_TO_EDIT"; then
    sed -i -E 's/(themeFontSize\s*=\s*)[0-9]+(\s*;)/\1'"$FONT_SIZE"'\2/' "$FILE_TO_EDIT"
  else
    echo "Error: 'themeFontSize' parameter was not found in $FILE_TO_EDIT."
    echo "It appears that this parameter has not been explicitly defined in your SicOS module configuration (it is currently using the default value of 10)."
    echo "Please manually edit your SicOS host configuration file ($FILE_TO_EDIT) and add:"
    echo "  themeFontSize = 10;"
    echo "  programs.sicos.hyprland.theming.fontSize = themeFontSize;"
    exit 1
  fi
fi

echo "Configuration file updated. Rebuilding the system..."

# Navigate to the flake's directory
pushd "$CONFIG_PATH"

# Rebuild the NixOS system with the new theme
sudo nixos-rebuild switch --flake .#$HOST-$DESKTOP

# Restart Waybar to apply theme changes
if command -v waybar &> /dev/null; then
    echo "Restarting Waybar to apply new theme..."
    pkill waybar || true
    sleep 1
    nohup uwsm app -- waybar > /dev/null 2>&1 &
fi

# Restart swaync to apply theme changes
if command -v swaync &> /dev/null; then
    echo "Restarting swaync to apply new theme..."
    pkill swaync || true
    sleep 1
    nohup uwsm app -- swaync > /dev/null 2>&1 &
fi

# Restart DankMaterialShell if active
if systemctl --user is-active --quiet dms.service; then
    echo "Restarting DankMaterialShell to apply new theme..."
    systemctl --user restart dms.service
fi

# Restart QuickShell if active
if command -v quickshell &> /dev/null; then
    # Only restart if it's actually running
    if pgrep quickshell > /dev/null; then
        echo "Restarting QuickShell to apply new theme..."
        pkill quickshell || true
        sleep 1
        nohup uwsm app -- quickshell > /dev/null 2>&1 &
    fi
fi

# Restart Walker to apply theme changes
if command -v walker &> /dev/null; then
    echo "Restarting Walker to apply new theme..."
    pkill walker || true
    sleep 1
    nohup uwsm app -- walker --gapplication-service > /dev/null 2>&1 &
fi

echo "   ___                 "
echo "  |   \ ___ _ _  ___   "
echo "  | |) / _ \ ' \/ -_)  "
echo "  |___/\___/_||_\___|  "
echo "                       "

if [ -n "$THEME" ]; then
    echo "Theme changed successfully to '$THEME'!"
fi
if [ -n "$SCHEME" ]; then
    echo "Scheme changed successfully to '$SCHEME'!"
fi
if [ -n "$FONT_SIZE" ]; then
    echo "Font size changed successfully to '${FONT_SIZE}pt'!"
fi
echo "Terminal will close in 3 seconds..."
sleep 3

# Changing wallpaper if theme was updated
if [ -n "$THEME" ]; then
    awww img --transition-type grow --transition-pos 0,0 --transition-step 90 $WALLPAPERS_PATH/sicos-$THEME.jpg
fi

kill $PPID
