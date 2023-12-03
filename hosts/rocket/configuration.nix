{ config, pkgs, inputs, username, ... }:

{
  ##########################################
  # Special configurations only for Rocket #
  ##########################################

  networking.hostName = "rocket"; # Define your hostname.

  # Enabling AMD-ATI driver
  boot = {
    initrd = {
      kernelModules = [ "amdgpu" ];
    };
  };

  # Enabling amdgpu driver on XServer
  services = {
    xserver = {
      videoDrivers = [ "amdgpu" ];
      displayManager = {
        defaultSession = "plasmawayland";
        sddm = {
          wayland = {
            enable = true;
          };
        };
      };
    };
  };
}
