#!/usr/bin/env bash

# Additional script for installing NixOS on strange
# -------------------------------------------------
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
sudo mkswap -L swap /dev/nvme0n1p3
sudo swapon /dev/nvme0n1p3