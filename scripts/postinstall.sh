#!/usr/bin/env bash

# Script for customizing NixOS after installation
# -----------------------------------------------
#
# @author: Eloy García Almadén
# @email: eloy.garcia.pca@gmail.com
# GitHub: https://github.com/egara/nixos-config
# -----------------------------------------------

set -euo pipefail

YADM_TOKEN="${1:-}"

if [ "$(id -u)" -eq 0 ]; then
  echo "ERROR! $(basename "$0") should be run as a regular user"
  exit 1
fi

if [[ -z "$YADM_TOKEN" ]]; then
  echo "ERROR! This script requires a yadm token to clone all the personal configuration into the system"
  exit 1
fi

sudo true

## Refactoring BTRFS subvolumes if it is needed
# if command -v btrfs >/dev/null; then
#   pushd "/"
#   echo "Refactoring BTRFS subvolumens. Please wait..."

#   sudo cp -ar ./srv ./srv2
#   sudo btrfs subvolume delete ./srv
#   sudo mv ./srv2 ./srv

#   sudo cp -ar ./tmp ./tmp2
#   sudo btrfs subvolume delete ./tmp
#   sudo mv ./tmp2 ./tmp

#   sudo btrfs subvolume delete ./var/lib/machines
#   sudo mkdir -p ./var/lib/machines

#   sudo btrfs subvolume delete ./var/lib/portables
#   sudo mkdir -p ./var/lib/portables
# else
#   echo "BTRFS filesystem not detected. Skipping BTRFS refactoring."
# fi

pushd "$HOME"

# Executing yadm in order to get all personal configurations for different applications
echo "Cloning yamd repository and applying custom bootstrap script"
yadm clone --bootstrap https://egara:$YADM_TOKEN@github.com/egara/yadm.git

# Changing URL in order to use imported ssh keys
yadm remote set-url origin git@github.com:egara/yadm

# Restoring KDE Plasma settings if it is needed
if command -v konsave >/dev/null; then
  echo "KDE Plasma desktop detected. Restoring settings. Please wait..."

  konsave -a plasma6-tiling
else
  echo "KDE Plasma desktop doesn't detected. Skipping settings restoration."
fi

# Executing ansible playbook for finishing customization
echo "Executing ansible playbook for finishing customization"
pushd "$HOME/.ansible"
ansible-playbook computers/nixos-desktop/playbooks/nixos-desktop-complete-instalation-01.yaml --ask-become-pass