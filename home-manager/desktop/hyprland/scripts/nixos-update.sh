#!/usr/bin/env bash

# Script for checking updates on NixOS
# ------------------------------------
#
# @author: Eloy García Almadén
# @email: eloy.garcia.pca@gmail.com
# -------------------------------------

# Same visual placement as the system info window: clean full screen presentation
printf '\e[?25l' # Hide cursor
clear

echo "==============================================="
echo "             NixOS System Update"
echo "==============================================="
echo

# Getting hostname
host="$(hostname)"
echo "The host that will be updated is $host"

# Getting desktop environment
desktop="$(echo $XDG_CURRENT_DESKTOP)"

# Renaming desktop environment
if [ "$desktop" = "Hyprland" ] || [ "$desktop" = "hyprland" ]; then
  desktop="hyprland"
elif [ "$desktop" = "KDE" ] || [ "$desktop" = "kde" ] || [ "$desktop" = "plasma" ]; then
  desktop="plasma"
fi

echo "Desktop environment detected: $desktop"
echo "Updating system with profile $host-$desktop. Please wait..."
echo

pushd "$HOME/Zero/nixos-config" > /dev/null

# Checking installed packages
echo "Updating packages. Please wait..."
nix flake update

# Checking updates
echo "Checking updates for $host. Please wait..."
nix build ".#nixosConfigurations.$host-$desktop.config.system.build.toplevel"

# Displaying differences between initial situation and updated situation
echo "These are the packages that will be updated"
nvd diff /run/current-system ./result

# Asking for system update
read -r -p "Do you want to update the system? [y/n] " updateSystem < /dev/tty

if [[ "$updateSystem" == "y" ]]; then
    # Updating the system
    echo "The system is going to be updated. Please wait..."
    nix flake update
    sudo nixos-rebuild switch --flake .#$host-$desktop
    echo "The system has been successfully updated"
else
    # Exit
    echo "Ok. Bye!"
fi

printf '\e[?25h' # Show cursor again

echo
echo "Press any key to close the window..."

# Wait for any keypress to exit, ensuring we read from the TTY
read -s -n 1 < /dev/tty
