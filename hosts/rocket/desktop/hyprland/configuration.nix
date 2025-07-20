{ config, pkgs, inputs, username, lib, ... }:

{
  ##########################################
  # Special configurations only for Rocket #
  # Hyprland                               #
  ##########################################

  # Enabling AMD-ATI driver
  boot = {
    initrd = {
      kernelModules = [ "amdgpu" ];
    };
  };

  # Video drivers for xserver
  services = {
    xserver = {
      videoDrivers = [ "amdgpu" ];
    };
  };
}
