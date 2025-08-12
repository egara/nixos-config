{ config, pkgs, inputs, username, lib, ... }:

{
  ####################################################
  # Special desktop configurations only for Ironman  #
  ####################################################

  # Video drivers for xserver
  services = {
    xserver = {
      videoDrivers = [ "nvidia" ];
    };
  };
}
