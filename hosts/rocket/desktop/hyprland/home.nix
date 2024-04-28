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

{ pkgs, config, ... }:

{
  imports = [
    # Wofi configuration via home-manager
    ../../../../home-manager/wofi

  ];

  home = {
    # Specific packages for rocket hyprland desktop
    packages = with pkgs; [
    ];

    # Hyprland configuration
    file.".config/hypr/hyprland.conf".source = ../../../../home-manager/hyprland/config-files/hyprland.conf;

    # Waybar configuration
    file.".config/waybar/config.jsonc".source = ../../../../home-manager/waybar/config-files/config.jsonc;
    file.".config/waybar/style.css".source = ../../../../home-manager/waybar/config-files/style.css;

    # Wlogout configuration
    file.".config/wlogout/layout".source = ../../../../home-manager/wlogout/config-files/layout;
    file.".config/wlogout/style.css".source = ../../../../home-manager/wlogout/config-files/style.css;
    file.".config/wlogout/icons/hibernate.png".source = ../../../../home-manager/wlogout/icons/hibernate.png;
    file.".config/wlogout/icons/lock.png".source = ../../../../home-manager/wlogout/icons/lock.png;
    file.".config/wlogout/icons/logout.png".source = ../../../../home-manager/wlogout/icons/logout.png;
    file.".config/wlogout/icons/reboot.png".source = ../../../../home-manager/wlogout/icons/reboot.png;
    file.".config/wlogout/icons/shutdown.png".source = ../../../../home-manager/wlogout/icons/shutdown.png;
    file.".config/wlogout/icons/suspend.png".source = ../../../../home-manager/wlogout/icons/suspend.png;

    # Dunst
    file.".config/dunst/dunstrc".source = ../../../../home-manager/dunst/config-files/dunstrc;

  };

  programs.home-manager.enable = true;

  home.pointerCursor = {
    gtk.enable = true;
    # x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 10;
  };

  gtk = {
    enable = true;
    theme = {
      package = pkgs.flat-remix-gtk;
      name = "Flat-Remix-GTK-Grey-Darkest";
    };

    iconTheme = {
      package = pkgs.gnome.adwaita-icon-theme;
      name = "Adwaita";
    };

    font = {
      name = "Sans";
      size = 11;
    };
  };

}
