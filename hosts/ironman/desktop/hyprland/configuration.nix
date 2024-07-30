{ config, pkgs, inputs, username, lib, ... }:

{
  ###########################################
  # Special configurations only for Ironman #
  # Hyprland                                #
  ###########################################

  # SDDM
  services = {
    displayManager = {
      sddm = {
        enable = true;
        wayland = {
          enable = true;
        };
      };
    };

    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];

      xkb = {
        layout = "es";
        variant = "";
      };
    };
  };
  
  # Swaylock (for locking session)
  security.pam.services.swaylock = {};

  # Modules
  imports = [
    # Hyprland common module
    ../../../../modules/desktop/hyprland.nix
  ];
}