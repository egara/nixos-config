#!/usr/bin/env bash

# Additional script for installing NixOS on a VM
# ----------------------------------------------
#
# @author: Eloy García Almadén
# @email: eloy.garcia.pca@gmail.com
# GitHub: https://github.com/egara/nixos-config
# Inspired by Martin Wimpress: https://github.com/wimpysworld/nix-config
# ----------------------------------------------

set -euo pipefail

sudo true

# Labeling swap
echo "Labeling swap..."
sudo swapoff -a
sudo mkswap -L swap /dev/sda4
sudo swapon /dev/sda4
