#!/usr/bin/env bash
printf '\e[?25l' # Hide cursor
clear
fastfetch -c all.jsonc
# Wait for any keypress to exit, ensuring we read from the TTY
read -s -n 1 < /dev/tty
