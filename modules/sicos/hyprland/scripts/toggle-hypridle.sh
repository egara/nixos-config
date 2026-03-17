#!/usr/bin/env bash

# Script for toggling hypridle
# -------------------------------------
#
# @author: Eloy García Almadén
# @email: eloy.garcia.pca@gmail.com
# -------------------------------------

if pgrep -x "hypridle" >/dev/null
then
    # Hypridle is running -> kill the process
    hyprctl dispatch exec "pkill hypridle"
    notify-send -t 2500 -u low -r 9993 "Hypridle" "Idle has been disabled"
else
    # Hypridle is not running -> run the process
    uwsm app -- hyprctl dispatch exec "hypridle &"
    notify-send -t 2500 -u low -r 9993 "Hypridle" "Idle has been enabled"
fi
