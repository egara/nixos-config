{ config, pkgs, inputs, username, lib, ... }:

{
  ###########################################
  # Special configurations only for Rocket  #
  # Plasma 6                                #
  ###########################################

  # SDDM
  services = {
    displayManager = {
      defaultSession = "plasma";
      sddm = {
        enable = true;
        wayland = {
          enable = true;
        };
      };
    };

    xserver = {
      enable = true;

      xkb = {
        layout = "es";
        variant = "";
      };
    };

    desktopManager = {
      plasma6 = {
        enable = true;
      };
    };
  };
}