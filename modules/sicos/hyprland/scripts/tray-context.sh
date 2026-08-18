#!/usr/bin/env bash

TARGET_ID="$1"
POS_X="$2"
POS_Y="$3"

ITEMS=$(dbus-send --session --print-reply --dest=org.kde.StatusNotifierWatcher /StatusNotifierWatcher org.freedesktop.DBus.Properties.Get string:org.kde.StatusNotifierWatcher string:RegisteredStatusNotifierItems 2>/dev/null)

while IFS= read -r line; do
  line="${line#*\"}"
  line="${line%\"*}"
  [ -z "$line" ] && continue
  
  BUS="${line%%/*}"
  OBJ="/${line#*/}"
  
  if [[ "$BUS" != :* ]]; then
    continue
  fi
  
  ID=$(dbus-send --session --print-reply --dest="$BUS" "$OBJ" org.freedesktop.DBus.Properties.Get string:org.kde.StatusNotifierItem string:Id 2>/dev/null | grep -oP "(?<=\")(.*?)(?=\")" | tail -1)
  
  if [ "$ID" = "$TARGET_ID" ]; then
    dbus-send --session --type=method_call --dest="$BUS" "$OBJ" org.kde.StatusNotifierItem.ContextMenu int32:"$POS_X" int32:"$POS_Y"
    exit 0
  fi
done <<< "$ITEMS"
