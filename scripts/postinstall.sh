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

pushd "$HOME"

if [[ -z "$YADM_TOKEN" ]]; then
  echo "ERROR! This script requires a yadm token to clone all the personal configuration into the system"
  exit 1
fi

yadm clone --bootstrap https://egara:$YADM_TOKEN@github.com/egara/yadm.git

sudo true

yadm remote set-url origin git@github.com:egara/yadm
