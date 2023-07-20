#!/usr/bin/env bash

# Script for installing NixOS
# ---------------------------
#
# @author: Eloy García Almadén
# @email: eloy.garcia.pca@gmail.com
# GitHub: https://github.com/egara/nixos-config
# Inspired by Martin Wimpress: https://github.com/wimpysworld/nix-config
# ---------------------------

set -euo pipefail

TARGET_HOST="${1:-}"
TARGET_USER="${2:-egarcia}"

if [ "$(id -u)" -eq 0 ]; then
  echo "ERROR! $(basename "$0") should be run as a regular user"
  exit 1
fi

if [ ! -d "$HOME/Zero/nixos-config/.git" ]; then
  git clone https://github.com/egara/nixos-config.git "$HOME/Zero/nixos-config"
fi

pushd "$HOME/Zero/nixos-config"

if [[ -z "$TARGET_HOST" ]]; then
  echo "ERROR! $(basename "$0") requires a hostname as the first argument"
  echo "       The following hosts are available"
  ls -1 nixos/*/boot.nix | cut -d'/' -f2 | grep -v iso
  exit 1
fi

if [[ -z "$TARGET_USER" ]]; then
  echo "ERROR! $(basename "$0") requires a username as the second argument"
  echo "       The following users are available"
  ls -1 nixos/_mixins/users/ | grep -v -E "nixos|root"
  exit 1
fi

sudo true

sudo nix run github:nix-community/disko \
  --extra-experimental-features "nix-command flakes" \
  --no-write-lock-file \
  -- \
  --mode zap_create_mount \
  "hosts/$TARGET_HOST/disko-config.nix"

# Executing additional scripts
echo "Executing additional scripts for host $TARGET_HOST..."
pushd "$HOME/Zero/nixos-config/hosts/$TARGET_HOST/scripts"
for script in *.sh; do
  bash "$script"
done

pushd "$HOME/Zero/nixos-config"

# Creating mounting point for BTRFS full volume
sudo mkdir -p /mnt/mnt/defvol

sudo nixos-install --no-root-password --flake ".#$TARGET_HOST"

# Rsync nix-config to the target install and set the remote origin to SSH.
rsync -a --delete "$HOME/Zero/" "/mnt/home/$TARGET_USER/Zero/"
pushd "/mnt/home/$TARGET_USER/Zero/nixos-config"
git remote set-url origin git@github.com:egara/nixos-config.git
popd
