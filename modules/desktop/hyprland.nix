{ config, pkgs, inputs, username, ... }:

{
  ##########################################
  # Hyprland                               #
  ##########################################

## Hyprland
  programs.hyprland = {
    enable = true; 
#    xwayland.hidpi = true;
    xwayland.enable = true;
  };

}
