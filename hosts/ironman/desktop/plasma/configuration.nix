{ config, pkgs, inputs, username, lib, ... }:

{
  ###########################################
  # Special configurations only for Rocket  #
  # Plasma 6                                #
  ###########################################

  # Video drivers for xserver
  services = {
    xserver = {
      videoDrivers = [ "nvidia" ];
    };
  };
}