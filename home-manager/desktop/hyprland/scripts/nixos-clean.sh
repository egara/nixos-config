#!/usr/bin/env bash

# Script for checking updates on NixOS
# ------------------------------------
#
# @author: Eloy García Almadén
# @email: eloy.garcia.pca@gmail.com
# -------------------------------------

# Cleaning journal logs. Only the last two days logs will remain
echo "Cleaning journal logs. Only the last two days logs will remain"
sudo journalctl --vacuum-time=2d

# Deleting all generations expect the current one (and save a lot of disk space)
echo "Deleting all generations except the current one"
sudo nix-collect-garbage -d

# Deleting home-manager profiles and other stuff that nix-collect-garbage doesn't do older than 10 days
nix-collect-garbage --delete-older-than 10d
