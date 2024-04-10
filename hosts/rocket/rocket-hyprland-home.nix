#
#  Home-manager configuration for desktop
#
#  flake.nix
#   ├─ ./hosts
#   │   └─ ./vm
#   │       └─ home.nix *
#   └─ ./modules
#       └─ ./desktop
#           └─ ./bspwm
#               └─ home.nix
#

{ pkgs, ... }:

{
  imports =
    [
      #../../modules/desktop/bspwm/home.nix  #Window Manager
    ];

  home = {
    # Specific packages for desktop
    packages = with pkgs; [
      filezilla
      pciutils
    ];

    # Hyprland configuration
    file.".config/hypr/hyprland.conf".source = ../../home-manager/hyprland/config-files/hyprland.conf;
  };
}
