#!/usr/bin/env bash

# Script for checking updates on NixOS
# ------------------------------------
#
# @author: Eloy García Almadén
# @email: eloy.garcia.pca@gmail.com
# -------------------------------------

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

pushd "$HOME/Zero/nixos-config"

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
echo "Do you want to update the system? [y/n]"
read updateSystem

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
