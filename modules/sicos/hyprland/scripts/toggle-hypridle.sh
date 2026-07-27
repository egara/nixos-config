#!/usr/bin/env bash

# Script for toggling hypridle
# -------------------------------------
#
# @author: Eloy García Almadén
# @email: eloy.garcia.pca@gmail.com
# -------------------------------------

if systemctl --user is-active --quiet hypridle.service
then
    # Hypridle is running -> stop the service
    systemctl --user stop hypridle.service
    notify-send -t 2500 -u low -r 9993 "Hypridle" "Idle has been disabled"
else
    # Hypridle is not running -> start the service
    systemctl --user start hypridle.service
    notify-send -t 2500 -u low -r 9993 "Hypridle" "Idle has been enabled"
fi
