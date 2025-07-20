{ config, pkgs, inputs, username, lib, ... }:

{
  ###########################################
  # Special configurations only for Ironman #
  # Hyprland                                #
  ###########################################

  # Video drivers for xserver
  services = {
    xserver = {
      videoDrivers = [ "nvidia" ];
    };
  };
}