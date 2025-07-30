{ config, pkgs, inputs, username, lib, ... }:

{
  ##########################################
  # Plasma 6                               #
  ##########################################

  services = {
    # SDDM
    displayManager = {
      sddm = {
        enable = true;
        wayland = {
          enable = true;
        };
        theme = "Elegant";
      };
    };

    # Xserver
    xserver = {
      enable = true;

      xkb = {
        layout = "es";
        variant = "";
      };
    };

    # Plasma 6
    desktopManager = {
      plasma6 = {
        enable = true;
      };
    };

    # Power profiles
    power-profiles-daemon = {
      enable = false;
    };
  };
}