{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.sicos.hyprland;

  # Helper script for Waybar to display Insync status.
  # It checks if Insync is running and if there are active sync operations
  # by querying Insync's internal logs database.
  # This script does not send notifications; its purpose is to provide Waybar status.
  insyncIntegrationScript = pkgs.writeShellScriptBin "insync-integration.sh" ''
    #!${pkgs.bash}/bin/bash
    
    # Path to the Insync logs database (standard Linux location)
    INS_LOGS_DB="$HOME/.config/Insync/logs.db"
    # KEYWORDS: The definitive list of log phrases indicating active syncing (Upload or Download)
    # 'download' for active download; 'AddCloudGDItem' and 'ADD' for active upload processing.
    SYNCING_KEYWORDS="AddCloudGDItem|ADD|download|processing|queue|RemoveCloudGDItem|DELETE"

    # --- Status Checks ---

    # Check if Insync is running (using pgrep -x for exact match)
    # The pgrep utility must be available in the Waybar environment (part of procps).
    if ! ${pkgs.procps}/bin/pgrep -x insync > /dev/null; then
        echo '{"text": "", "tooltip": "Insync is not running", "class": "error"}'
        exit 0
    fi

    # Check for active syncing using log messages
    # This is the most reliable method, as it uses Insync's internal status records.
    SYNCING_COUNT=$(${pkgs.sqlite}/bin/sqlite3 "$INS_LOGS_DB" "SELECT message FROM logs ORDER BY created DESC LIMIT 10;" \
        | ${pkgs.gnugrep}/bin/grep -E -i "$SYNCING_KEYWORDS" \
        | ${pkgs.coreutils}/bin/wc -l)
                    
    # --- Process and Output Status ---

    ICON="󰅟"
    CLASS="synced"
    TOOLTIP_TEXT="Insync: All files synced"

    if [ "$SYNCING_COUNT" -gt 0 ]; then
        # If the count is > 0, it means an active sync file was found.
        ICON="󰘿" # Cloud with spinning arrows
        CLASS="syncing"
        TOOLTIP_TEXT="Insync is currently syncing..."
    fi

    # --- Output the result as JSON for Waybar ---
    # Using echo with the icon character directly in the JSON string.
    # We ensure the script uses the necessary utilities and quotes correctly.
    # Use echo and ensure the shell is robust enough to handle the UTF-8 characters.
    # The shebang '#!/usr/bin/env sh' at the top of the file helps here.

    JSON_OUTPUT='{"text": "'"$ICON"'", "tooltip": "'"$TOOLTIP_TEXT"'", "class": "'"$CLASS"'"}'
    echo "$JSON_OUTPUT"
  '';

in
{
  # This configuration will be applied only if the user explicitly enables Insync integration
  # in the sicos hyprland module.
  config = mkIf cfg.insync.enable {
    environment.systemPackages = with pkgs; [
      # The insync package itself.
      cfg.insync.package
      # The script for Waybar status.
      insyncIntegrationScript
      # Dependency for the script to query Insync's database.
      sqlite
    ];
  };
}