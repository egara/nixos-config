#!/usr/bin/env bash

# Script for balancing the BTRFS filesystem (ButterManager style)
# ---------------------------------------------------------------
#
# It compacts the data and metadata chunks that are left too empty
# after deleting snapshots and other filesystem cleaning operations.
#
# @author: Eloy García Almadén
# @email: eloy.garcia.pca@gmail.com
# -------------------------------------

# Usage: btrfs-balance.sh <mount_point> <data_usage> <metadata_usage>
MOUNT_POINT="${1:-/}"
DATA_USAGE="${2:?Data usage percentage is needed}"
METADATA_USAGE="${3:?Metadata usage percentage is needed}"

# Same visual placement as the system info window: clean full screen presentation
printf '\e[?25l' # Hide cursor
clear

echo "==============================================="
echo "            BTRFS Filesystem Balance"
echo "==============================================="
echo
# Warning message displayed while balancing:
# the window must not be closed until the operation is done
echo "Balancing '$MOUNT_POINT' mounted point."
echo
echo "Please wait..."
echo

# Requesting sudo credentials upfront; the starting message is painted as soon
# as the password is entered and validated
sudo -v
echo "Starting balance operation. Please wait..."
echo

# Balancing data chunks with usage lower than the current data usage
# (ButterManager: btrfs balance start -dusage=<data_percentage>)
echo "Balancing data chunks with usage lower than $DATA_USAGE%. Please wait..."
sudo btrfs balance start -dusage="$DATA_USAGE" "$MOUNT_POINT"

echo

# Balancing metadata chunks with usage lower than the current metadata usage
# (ButterManager: btrfs balance start -musage=<metadata_percentage>)
echo "Balancing metadata chunks with usage lower than $METADATA_USAGE%. Please wait..."
sudo btrfs balance start -musage="$METADATA_USAGE" "$MOUNT_POINT"

echo
echo "Filesystem balance finished"

printf '\e[?25h' # Show cursor again

echo
echo "Press any key to close the window..."

# Wait for any keypress to exit, ensuring we read from the TTY
read -s -n 1 < /dev/tty
