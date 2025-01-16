#
#  Home-manager configuration for desktop

{ pkgs, config, hyprland-plugins, ... }:

{
  imports = [
    # Wofi configuration via home-manager
    ../../../../home-manager/wofi

  ];

  home = {
    # Specific packages for hyprland desktop
    packages = with pkgs; [
    ];

    # Hyprland configuration
    #file.".config/hypr/hyprland.conf".source = ../../../../home-manager/hyprland/config-files/hyprland.conf;
    file.".config/hypr/change-wallpaper.sh".source = ../../../../home-manager/hyprland/scripts/change-wallpaper.sh;
    file.".config/hypr/disable-laptop-screen.sh".source = ../../../../home-manager/hyprland/scripts/disable-laptop-screen.sh;

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

    # QMMP
    # If QMMP doesn't switch to Winamp skin automatically, go to Edit -> Settings -> Plugins and check
    # Skinned User Interface within User Interfaces section. Then, restart QMMP
    file.".config/qmmp/skins/winamp_classic.wsz".source = ../../../../home-manager/qmmp/skins/winamp_classic.wsz;    

  };

  # Virtual Manager special configuration (https://nixos.wiki/wiki/Virt-manager)
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

  programs.home-manager.enable = true;
  
  # Cursor theming
  home.pointerCursor = {
    gtk.enable = true;
    # x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 10;
  };

  # GTK configuration and theming
  gtk = {
    enable = true;

    # theme = {
    #   name = "Catppuccin-Macchiato-Compact-Pink-Dark";
    #   package = pkgs.catppuccin-gtk.override {
    #     accents = [ "pink" ];
    #     size = "compact";
    #     tweaks = [ "rimless" "black" ];
    #     variant = "macchiato";
    #   };
    # };

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

    xdg.configFile = {
      "hypr/hyprland.conf".source = ../../../../home-manager/hyprland/config-files/hyprland.conf;
  #   "gtk-4.0/assets".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/assets";
  #   "gtk-4.0/gtk.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk.css";
  #   "gtk-4.0/gtk-dark.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk-dark.css";
    };

  # QT configuration and theming
  # qt = {
  #   enable = true;

  #   platformTheme = {
  #     name = "gtk";
  #   };

  #   style = {
  #     name = "gtk2";
  #     package = pkgs.catppuccin-kde;
  #   };
  # };

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

  # Hyprland special configuration for using plugins via Home Manager
  wayland.windowManager.hyprland = {

    enable = true;

    plugins = [
      hyprland-plugins.packages."${pkgs.system}".borders-plus-plus
    ];

    settings = {
      "plugin:borders-plus-plus" = {
        add_borders = 1; # 0 - 9

        # you can add up to 9 borders
        "col.border_1" = "rgb(ffffff)";
        "col.border_2" = "rgb(2222ff)";

        # -1 means "default" as in the one defined in general:border_size
        border_size_1 = 10;
        border_size_2 = -1;

        # makes outer edges match rounding of the parent. Turn on / off to better understand. Default = on.
        natural_rounding = "yes";
      };
    };
  };


}