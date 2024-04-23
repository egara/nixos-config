{ config, pkgs, inputs, username, ... }:

{
  ##########################################
  # Special configurations only for Rocket #
  # Hyprland                               #
  ##########################################

  networking.hostName = "rocket"; # Define your hostname.

  # Enabling AMD-ATI driver
  boot = {
    initrd = {
      kernelModules = [ "amdgpu" ];
    };
  };

  # SDDM
  services = {
    xserver = {
      enable = true;
      videoDrivers = [ "amdgpu" ];
      layout = "es";
      xkbVariant = "";
      displayManager = {
        sddm = {
          enable = true;
          wayland = {
            enable = true;
          };
        };
      };
    };
  };

  # Modules
  imports = [
    # Hyprland common module
    ../../../../modules/desktop/hyprland.nix
  ];

}
