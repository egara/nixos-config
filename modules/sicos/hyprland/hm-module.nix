{ config, pkgs, lib, nixosConfig, ... }:

let
  cfg = nixosConfig.programs.sicos.hyprland;
in
{
  # This is a home-manager module.
  # It's imported into a user's home-manager configuration.
  config = lib.mkMerge [
    (lib.mkIf cfg.enable (
      let
        # Conditionally define the attribute set for the walker light theme
        walkerLightTheme = lib.optionalAttrs (cfg.theming.mode == "light") {
          ".config/walker/themes/sicos-light/style.css".source = cfg.walker.lightThemeFile;
        };
      in
      {
        home.file = {
          # Hyprland files
          ".config/hypr/hyprland.conf".source = cfg.hyprland.configFile;
          ".config/hypr/pop-sound.mp3".source = ./config-files/pop-sound.mp3;

          # Hyprlock files
          ".config/hypr/hyprlock.conf".source = cfg.hyprlock.configFile;
          ".config/hypr/user.jpg".source = cfg.hyprlock.profilePicture;

          # Hypridle file
          ".config/hypr/hypridle.conf".source = cfg.hypridle.configFile;

          # Waybar files
          ".config/waybar/config.jsonc".source = cfg.waybar.configFile;
          ".config/waybar/style.css".source = cfg.waybar.styleFile;

          # Wlogout files
          ".config/wlogout/layout".source = cfg.wlogout.layoutFile;
          ".config/wlogout/style.css".source = cfg.wlogout.styleFile;
          ".config/wlogout/icons/hibernate.png".source = cfg.wlogout.hibernateIcon;
          ".config/wlogout/icons/lock.png".source = cfg.wlogout.lockIcon;
          ".config/wlogout/icons/logout.png".source = cfg.wlogout.logoutIcon;
          ".config/wlogout/icons/reboot.png".source = cfg.wlogout.rebootIcon;
          ".config/wlogout/icons/shutdown.png".source = cfg.wlogout.shutdownIcon;
          ".config/wlogout/icons/suspend.png".source = cfg.wlogout.suspendIcon;
          
          # Black icons for light theme
          ".config/wlogout/icons/hibernate-black.png".source = ./config-files/wlogout/icons/hibernate-black.png;
          ".config/wlogout/icons/lock-black.png".source = ./config-files/wlogout/icons/lock-black.png;
          ".config/wlogout/icons/logout-black.png".source = ./config-files/wlogout/icons/logout-black.png;
          ".config/wlogout/icons/reboot-black.png".source = ./config-files/wlogout/icons/reboot-black.png;
          ".config/wlogout/icons/shutdown-black.png".source = ./config-files/wlogout/icons/shutdown-black.png;
          ".config/wlogout/icons/suspend-black.png".source = ./config-files/wlogout/icons/suspend-black.png;

          # Swaync files
          ".config/swaync/config.json".source = cfg.swaync.configFile;
          ".config/swaync/style.css".source = cfg.swaync.styleFile;

          # Swappy file
          ".config/swappy/config".source = cfg.swappy.configFile;

          # Walker file
          ".config/walker/config.toml".source = cfg.walker.configFile;

          # Scripts (marked as executable)
          ".config/hypr/" = {
              source = cfg.scripts.path;
              recursive = true;
              executable = true;
          };

          # Wallpapers
          ".config/hypr/wallpapers" = {
              source = ./wallpapers;
              recursive = true;
          };
        } // walkerLightTheme; # Merge the conditional theme file

        # Configuring xdg-utils to use some default applications in Hyprland
        xdg.mimeApps = {
          enable = true;
          defaultApplications = {
            "text/x-nix" = "sublime_text.desktop";
            "text/plain" = "sublime_text.desktop";
            "text/markdown" = "sublime_text.desktop";
            "application/javascript" = "sublime_text.desktop";
            "application/json" = "sublime_text.desktop";
            "application/x-yaml" = "sublime_text.desktop";
            "text/css" = "sublime_text.desktop";
            "text/html" = "firefox.desktop";
            "x-scheme-handler/http" = "firefox.desktop";
            "x-scheme-handler/https" = "firefox.desktop";
            "application/pdf" = "org.kde.okular.desktop";
            "application/x-pdf" = "org.kde.okular.desktop";
            "x-terminal-emulator" = "kitty.desktop";
            "inode/directory" = "thunar.desktop";
            "x-scheme-handler/file" = "thunar.desktop";
            "video/mp4" = "vlc.desktop";
            "video/webm" = "vlc.desktop";
            "video/x-matroska" = "vlc.desktop";
            "audio/mpeg" = "qmmp.desktop";
            "image/jpeg" = "feh.desktop";
            "image/png" = "feh.desktop";
          };
        };

        # Kitty terminal emulator special configuration
        programs.kitty = {
          enable = true;
          shellIntegration.enableBashIntegration = true;
        };
      }
    ))
    (lib.mkIf cfg.theming.enable {
      ########################################
      # Theming with Stylix
      ########################################
      stylix =
        let
          # Base configuration
          commonConfig = {
            enable = true;
            cursor = {
              package = pkgs.bibata-cursors;
              name = "Bibata-Modern-Classic";
              size = 10;
            };
            icons = {
              package = pkgs.papirus-icon-theme;
              dark = "Papirus-Dark";
              light = "Papirus";
            };
            fonts = let
              monospaceFont = {
                package = pkgs.nerd-fonts.go-mono;
                name = "GoMonoNerdFontPropo-Bold";
              };
            in {
              monospace = monospaceFont;
              serif = monospaceFont;
              sansSerif = monospaceFont;
              emoji = {
                package = pkgs.noto-fonts-color-emoji;
                name = "Noto Color Emoji";
              };
              sizes = {
                applications = 10;
                desktop = 10;
                popups = 10;
                terminal = 10;
              };
            };
            targets = {
              kitty.enable = true;

              # Yazi is working again with stylix. The custom theming
              # configuration within /hosts/home.nix is disabled
              # [Yazi theming is not currently working using Stylix so
              # it is disabled and it will only take into account user's
              # configurations]
              yazi = {
                enable = true;
                 boldDirectory = true;
                 colors = {
                   enable = true;
                 };
              };

              # GTK and QT theming will be managed by Home Manger (see above)
              gtk = {
                enable = false;
              };

              qt = {
                enable = false;
              };

            };
          };

          # Dark theme
          darkTheme = commonConfig // {
            polarity = "dark";
            base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
            image = ./wallpapers/fwd-wallhaven-wallhaven-mprye8.jpg;
          };

          # Light Theme
          lightTheme = commonConfig // {
            polarity = "light";
            base16Scheme = "${pkgs.base16-schemes}/share/themes/equilibrium-light.yaml";
            image = ./wallpapers/fwd-wallhaven-wallhaven-v9v3r5.jpg; # Un fondo de pantalla claro
          };

        # Selecting stylix theming depending on the theme selected by the user
        in if cfg.theming.mode == "light" then lightTheme else darkTheme;

      #############################
      # Theming with Home Manager #
      #############################
      # Cursor theming will be globally managed by stylix (see below)
      #home.pointerCursor = {
      #  gtk.enable = true;
      #  package = pkgs.bibata-cursors;
      #  name = "Bibata-Modern-Classic";
      #  size = 10;
      #};

      # GTK configuration and theming
      gtk = {
        enable = true;
        theme = {
          name = if config.stylix.polarity == "dark" then "Adwaita-dark" else "Adwaita";
          package = pkgs.gnome-themes-extra;
        };
        iconTheme = {
          name = config.stylix.icons.${config.stylix.polarity};
          package = config.stylix.icons.package;
        };
        font = {
          name = config.stylix.fonts.sansSerif.name;
          size = config.stylix.fonts.sizes.applications;
        };
        gtk3.extraConfig.gtk-application-prefer-dark-theme = config.stylix.polarity == "dark";
        gtk4.extraConfig.gtk-application-prefer-dark-theme = config.stylix.polarity == "dark";
      };

      # QT configuration and theming
      qt = {
        enable = true;
        platformTheme.name = "gtk";
        style = {
          name = if config.stylix.polarity == "dark" then "adwaita-dark" else "adwaita";
          package = pkgs.adwaita-qt;
        };
      };
    })
    (lib.mkIf cfg.kanshi.enable {
      ##########################################
      # Kanshi configuration with Home Manager 
      ##########################################

      home.file = {
        # Kanshi configuration file
        ".config/kanshi/config".source = cfg.kanshi.configFile;
      };

      # Kanshi (multi monitoring layout management)
      services.kanshi = {
        enable = true;
        systemdTarget = "hyprland-session.target";
        # Settings will be set using a file
        # settings = [
        #   {
        #     profile = {
        #       name = "home";
        #       outputs = [
        #         { criteria = "eDP-1"; scale = 1.0; status = "enable"; mode = "1920x1080"; position = "1920,0"; }
        #         { criteria = "HDMI-A-2"; scale = 1.0; status = "enable"; mode = "1920x1080"; position = "0,0"; }
        #       ];
        #     };
        #   }
        #   {
        #     profile = {
        #       name = "office";
        #       outputs = [
        #         { criteria = "DP-2"; scale = 1.0; status = "enable"; mode = "1920x1080"; position = "0,0"; }
        #         { criteria = "DP-1"; scale = 1.0; status = "enable"; mode = "1920x1080"; position = "1920,0"; }
        #         { criteria = "eDP-1"; status = "disable"; }
        #       ];
        #     };
        #   }
        #   {
        #     profile = {
        #       name = "meeting-room";
        #       outputs = [
        #         { criteria = "DP-2"; scale = 1.0; status = "enable"; mode = "1920x1080"; position = "0,0"; }
        #         { criteria = "eDP-1"; scale = 1.0; status = "enable"; mode = "1920x1080"; position = "1920,0"; }
        #       ];
        #     };
        #   }
        #   {
        #     profile = {
        #       name = "undocked";
        #       outputs = [ { criteria = "eDP-1"; scale = 1.0; status = "enable"; mode = "1920x1080"; position = "0,0"; } ];
        #     };
        #   }
        # ];
      };      
    })
  ];
}
