{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.sicos.power-management;

  # Helper script to send notifications as the logged-in graphical user.
  # This is necessary because udev rules run as root in a session-less environment,
  # and notify-send needs to connect to the user's D-Bus session.
  notifyAsUser = pkgs.writeShellScriptBin "notify-as-user" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    
    # Find the user on seat0, which corresponds to the active graphical user.
    SESSION_INFO=$(${pkgs.systemd}/bin/loginctl list-sessions --no-legend | ${pkgs.gnugrep}/bin/grep seat0 | ${pkgs.gawk}/bin/awk '{print $1, $3}' | ${pkgs.coreutils}/bin/head -n 1)
    if [ -z "$SESSION_INFO" ]; then
        ${pkgs.util-linux}/bin/logger -t power-management "notifyAsUser: No active graphical session found, skipping notification."
        exit 0 # Exit gracefully. Not finding a user isn't a fatal error for the main script.
    fi
    
    SESSION_ID=$(echo "$SESSION_INFO" | ${pkgs.gawk}/bin/awk '{print $1}')
    USER=$(echo "$SESSION_INFO" | ${pkgs.gawk}/bin/awk '{print $2}')
    USER_ID=$(${pkgs.coreutils}/bin/id -u "$USER")
    
    # Export the necessary environment variables for the user's session.
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus"
    
    # Try to get the display from the session details, falling back to :0.
    DISPLAY_INFO=$(${pkgs.systemd}/bin/loginctl show-session "$SESSION_ID" -p Display --value)
    if [ -n "$DISPLAY_INFO" ]; then
        export DISPLAY="$DISPLAY_INFO"
    else
        export DISPLAY=":0"
    fi
    
    ${pkgs.util-linux}/bin/logger -t power-management "notifyAsUser: Sending notification to user $USER on display $DISPLAY"
    
    # Execute notify-send as the user, passing all arguments from this script.
    ${pkgs.sudo}/bin/sudo -u "$USER" \
      DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS \
      DISPLAY=$DISPLAY \
      ${pkgs.libnotify}/bin/notify-send "$@"
  '';

  powerSaverScript = pkgs.writeShellScriptBin "power-saver-mode" ''
    # Send notification via the helper script
    ${notifyAsUser}/bin/notify-as-user -t 3500 -u low -r 9993 "Energy Profile" " Power-saver "

    # Switch to power-saver profile using absolute paths
    ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver
    ${pkgs.util-linux}/bin/logger -t power-management "Switched to power-saver profile due to AC unplug."

    # Reduce brightness to 50% using absolute paths
    BRIGHTNESS_MAX=$(${pkgs.brightnessctl}/bin/brightnessctl max)
    BRIGHTNESS_50=$(echo "$BRIGHTNESS_MAX * 0.5" | ${pkgs.bc}/bin/bc | ${pkgs.coreutils}/bin/cut -d'.' -f1)
    ${pkgs.brightnessctl}/bin/brightnessctl set "$BRIGHTNESS_50"
    ${pkgs.util-linux}/bin/logger -t power-management "Reduced brightness to 50% ($BRIGHTNESS_50/$BRIGHTNESS_MAX) due to AC unplug."
  '';

  balancedModeScript = pkgs.writeShellScriptBin "balanced-mode" ''
    # Send notification via the helper script
    ${notifyAsUser}/bin/notify-as-user -t 3500 -u low -r 9993 "Energy Profile" " Balanced "

    # Switch to balanced profile using absolute paths
    ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set balanced
    ${pkgs.util-linux}/bin/logger -t power-management "Switched to balanced profile due to AC plug."

    # Restore brightness to 100% using absolute paths
    ${pkgs.brightnessctl}/bin/brightnessctl set 100%
    ${pkgs.util-linux}/bin/logger -t power-management "Restored brightness to 100% due to AC plug."
  '';
in
{
  options.sicos.power-management = {
    enable = mkEnableOption "Enable automatic power management on AC plug/unplug.";
  };

  config = mkIf cfg.enable {
    # Ensure necessary packages and our custom scripts are available in the system PATH
    environment.systemPackages = with pkgs; [
      # External dependencies
      power-profiles-daemon
      brightnessctl
      bc # for floating point arithmetic in script
      libnotify # for on-screen notifications
      sudo # needed by notifyAsUser script

      # Add our custom scripts to the system PATH
      powerSaverScript
      balancedModeScript
      notifyAsUser
    ];


    # Enable power-profiles-daemon service
    services.power-profiles-daemon.enable = true;

    # Udev rules to trigger scripts on AC plug/unplug
    services.udev.extraRules = ''
      # Rule for AC unplug: run power-saver script
      SUBSYSTEM=="power_supply", ACTION=="change", ENV{POWER_SUPPLY_TYPE}=="Mains", ENV{POWER_SUPPLY_ONLINE}=="0", RUN+="${powerSaverScript}/bin/power-saver-mode"
      # Rule for AC plug: run balanced-mode script
      SUBSYSTEM=="power_supply", ACTION=="change", ENV{POWER_SUPPLY_TYPE}=="Mains", ENV{POWER_SUPPLY_ONLINE}=="1", RUN+="${balancedModeScript}/bin/balanced-mode"
    '';
  };
}
