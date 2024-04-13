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

    # Waybar configuration
    file.".config/waybar/config.jsonc".source = ../../home-manager/waybar/config-files/config.jsonc;
    file.".config/waybar/style.css".source = ../../home-manager/waybar/config-files/style.css;

    # Wlogout configuration
    ".config/wlogout/layout".source = ../../home-manager/wlogout/config-files/layout;
    ".config/wlogout/style.css".source = ../../home-manager/wlogout/config-files/style.css;
    ".config/wlogout/icons/hibernate.png".source = ../../home-manager/wlogout/icons/hibernate.png;
    ".config/wlogout/icons/lock.png".source = ../../home-manager/wlogout/icons/lock.png;
    ".config/wlogout/icons/logout.png".source = ../../home-manager/wlogout/icons/logout.png;
    ".config/wlogout/icons/reboot.png".source = ../../home-manager/wlogout/icons/reboot.png;
    ".config/wlogout/icons/shutdown.png".source = ../../home-manager/wlogout/icons/shutdown.png;
    ".config/wlogout/icons/suspend.png".source = ../../home-manager/wlogout/icons/suspend.png;
  };
}
