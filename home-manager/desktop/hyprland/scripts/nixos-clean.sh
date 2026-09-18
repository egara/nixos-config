#!/usr/bin/env bash

# Script for cleaning NixOS
# ------------------------------------
#
# @author: Eloy García Almadén
# @email: eloy.garcia.pca@gmail.com
# -------------------------------------

# Same visual placement as the system info window: clean full screen presentation
printf '\e[?25l' # Hide cursor
clear

echo "==============================================="
echo "             NixOS System Clean"
echo "==============================================="
echo

# Cleaning journal logs. Only the last two days logs will remain
echo "Cleaning journal logs. Only the last two days logs will remain"
sudo journalctl --vacuum-time=2d

# Deleting all generations expect the current one (and save a lot of disk space)
echo "Deleting all generations except the current one"
sudo nix-collect-garbage -d

# Deleting home-manager profiles and other stuff that nix-collect-garbage doesn't do older than 10 days
echo "Deleting home-manager profiles and generations older than 10 days"
nix-collect-garbage --delete-older-than 10d

echo
echo "System cleaning finished"

printf '\e[?25h' # Show cursor again

echo
echo "Press any key to close the window..."

# Wait for any keypress to exit, ensuring we read from the TTY
read -s -n 1 < /dev/tty
