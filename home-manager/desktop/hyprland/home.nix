#
#  Home-manager configuration for desktop

# { pkgs, config, hyprland-plugins, ... }:
{ pkgs, ... }:

let
  # Variables can be defined here
in {
  imports = [
    # Wofi configuration via home-manager
    #../../wofi
  ];

  home = {
    # Specific packages for hyprland desktop
    packages = with pkgs; [
    ];

    # Hyprland configuration
    file.".config/hypr/hyprland.conf".source = ./config-files/hyprland.conf;
    file.".config/hypr/monitors.conf".source = ./config-files/monitors.conf;
    file.".config/hypr/bindings.conf".source = ./config-files/bindings.conf;
    file.".config/hypr/env.conf".source = ./config-files/env.conf;    
    file.".config/hypr/init.conf".source = ./config-files/init.conf; 
    file.".config/hypr/change-wallpaper.sh".source = ./scripts/change-wallpaper.sh;
    file.".config/hypr/nixos-update.sh".source = ./scripts/nixos-update.sh;
    file.".config/hypr/nixos-clean.sh".source = ./scripts/nixos-clean.sh;
    file.".config/hypr/nixos-scripts.sh".source = ./scripts/nixos-scripts.sh;
    file.".config/hypr/disable-laptop-screen.sh".source = ./scripts/disable-laptop-screen.sh;

    # Waybar configuration
    file.".config/waybar/config.jsonc".source = ../../waybar/config-files/config.jsonc;
    file.".config/waybar/style.css".source = ../../waybar/config-files/style.css;

    # Wlogout configuration
    file.".config/wlogout/layout".source = ../../wlogout/config-files/layout;
    file.".config/wlogout/style.css".source = ../../wlogout/config-files/style.css;
    file.".config/wlogout/icons/hibernate.png".source = ../../wlogout/icons/hibernate.png;
    file.".config/wlogout/icons/lock.png".source = ../../wlogout/icons/lock.png;
    file.".config/wlogout/icons/logout.png".source = ../../wlogout/icons/logout.png;
    file.".config/wlogout/icons/reboot.png".source = ../../wlogout/icons/reboot.png;
    file.".config/wlogout/icons/shutdown.png".source = ../../wlogout/icons/shutdown.png;
    file.".config/wlogout/icons/suspend.png".source = ../../wlogout/icons/suspend.png;

    # Dunst
    file.".config/dunst/dunstrc".source = ../../dunst/config-files/dunstrc;

    # Walker
    file.".config/walker/config.toml".source = ../../walker/config.toml;
  };
  
  # Cursor theming
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 10;
  };

  # GTK configuration and theming
  gtk = {
    enable = true;

    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };

    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };

    font = {
      package = pkgs.nerd-fonts.go-mono;
      name = "GoMonoNerdFontPropo-Bold";
      size = 10;
    };

    gtk3 = {
      extraConfig.gtk-application-prefer-dark-theme = true;
    };    

    gtk4 = {
      extraConfig.gtk-application-prefer-dark-theme = true;
    };    
  };

    # These configuration files will be used instead of the configuration defined in settings for modules installed and managed via Home Manager
    # such as hyprland. This way, settings within hyprland home manager configuration (see below) can be empty
    # Be aware that the directory by default for storing all this configuration files will be ~/.config
    xdg.configFile = {
  #   "hypr/hyprland.conf".source = ../../hyprland/config-files/hyprland.conf;
  #   "gtk-4.0/assets".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/assets";
  #   "gtk-4.0/gtk.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk.css";
  #   "gtk-4.0/gtk-dark.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk-dark.css";
    };

  # QT configuration and theming
  qt = {
    enable = true;
    platformTheme = {
      name = "gtk";
    };
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };

  # Kitty terminal emulator special configuration
  programs.kitty = {
    enable = true;
    font = {
      package = pkgs.nerd-fonts.go-mono;
      name = "GoMonoNerdFontPropo-Bold";
      size = 10;
    };
    themeFile = "Catppuccin-Mocha";
    shellIntegration = {
      enableBashIntegration = true;
    };
  };

}