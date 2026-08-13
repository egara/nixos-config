{
  config,
  pkgs,
  lib,
  nixosConfig,
  ...
}:

let
  cfg = nixosConfig.programs.sicos.hyprland;
in
{
  # This is a home-manager module.
  # It's imported into a user's home-manager configuration.
  config = lib.mkMerge [
    (lib.mkIf cfg.enable ({
      home.file = {
        # Hyprland files
        ".config/hypr/hyprland.lua".source = cfg.hyprland.configFile;
        # ".config/hypr/hyprland.conf".source = cfg.hyprland.configFile;
        ".config/hypr/pop-sound.mp3".source = ./config-files/pop-sound.mp3;

        # Hyprlock files
        ".config/hypr/hyprlock.conf".source = cfg.hyprlock.configFile;
        ".config/hypr/user.jpg".source = cfg.hyprlock.profilePicture;

        # Hypridle file
        ".config/hypr/hypridle.conf".source = cfg.hypridle.configFile;

        # Waybar files
        ".config/waybar/config.jsonc" = lib.mkIf (cfg.shell == "waybar") {
          text = if cfg.waybar.overwrite then (builtins.readFile cfg.waybar.configFile)
                 else (import ./config-files/waybar/waybar-config.nix { inherit config lib nixosConfig; });
        };
        ".config/waybar/style.css" = lib.mkIf (cfg.shell == "waybar") {
          text = if cfg.waybar.overwrite then (builtins.readFile cfg.waybar.styleFile)
                 else (import ./config-files/waybar/waybar-style.nix { inherit config lib nixosConfig; });
        };

        # Wlogout files
        ".config/wlogout/layout".source = cfg.wlogout.layoutFile;
        ".config/wlogout/style.css".text =
          if cfg.wlogout.overwrite then
            (builtins.readFile cfg.wlogout.styleFile)
          else
            (import ./config-files/wlogout/wlogout-style.nix {
              inherit
                config
                lib
                pkgs
                nixosConfig
                ;
            });
        ".config/wlogout/icons/hibernate.png".source = cfg.wlogout.hibernateIcon;
        ".config/wlogout/icons/lock.png".source = cfg.wlogout.lockIcon;
        ".config/wlogout/icons/logout.png".source = cfg.wlogout.logoutIcon;
        ".config/wlogout/icons/reboot.png".source = cfg.wlogout.rebootIcon;
        ".config/wlogout/icons/shutdown.png".source = cfg.wlogout.shutdownIcon;
        ".config/wlogout/icons/suspend.png".source = cfg.wlogout.suspendIcon;

        # Black icons for light theme
        ".config/wlogout/icons/hibernate-black.png".source =
          ./config-files/wlogout/icons/hibernate-black.png;
        ".config/wlogout/icons/lock-black.png".source = ./config-files/wlogout/icons/lock-black.png;
        ".config/wlogout/icons/logout-black.png".source = ./config-files/wlogout/icons/logout-black.png;
        ".config/wlogout/icons/reboot-black.png".source = ./config-files/wlogout/icons/reboot-black.png;
        ".config/wlogout/icons/shutdown-black.png".source = ./config-files/wlogout/icons/shutdown-black.png;
        ".config/wlogout/icons/suspend-black.png".source = ./config-files/wlogout/icons/suspend-black.png;

        # Swaync files
        ".config/swaync/config.json" = lib.mkIf (cfg.shell == "waybar") {
          source = cfg.swaync.configFile;
        };
        ".config/swaync/style.css" = lib.mkIf (cfg.shell == "waybar") {
          text = if cfg.swaync.overwrite then (builtins.readFile cfg.swaync.styleFile)
                 else (import ./config-files/swaync/swaync-style.nix { inherit config lib nixosConfig; });
        };

        # Walker files
        ".config/walker/config.toml".source = ./config-files/walker/config.toml;
        ".config/walker/themes/stylix/style.css".text =
          import ./config-files/walker/themes/stylix/walker-style.nix
            { inherit config lib nixosConfig; };

        # UWSM environment variables
        # (Needed because uwsm cannot parse hyprland.lua to extract env vars)
        ".config/uwsm/env".text = ''
          export XCURSOR_SIZE=24
          export GDK_BACKEND=wayland
          export XDG_CURRENT_DESKTOP=Hyprland
          export XDG_SESSION_TYPE=wayland
          export XDG_SESSION_DESKTOP=Hyprland
          export TERMINAL=kitty
        '';

        # Scripts (marked as executable)
        ".config/sicos/scripts/" = {
          source = cfg.scripts.path;
          recursive = true;
          executable = true;
        };
        
        ".config/sicos/scripts/start-shell.sh" = {
          text = ''
            #!/usr/bin/env bash
            ${if cfg.shell == "waybar" then ''
              uwsm app -- waybar &
              uwsm app -- swaync &
            '' else ''
              # DankMaterialShell is managed by its own systemd service.
              # systemctl --user start dms.service
            ''}
          '';
          executable = true;
        };

        # SicOS themes
        ".config/sicos/themes" = {
          source = ./themes;
          recursive = true;
        };

        # SicOS screensaver
        ".config/sicos/screensaver" = {
          source = ./screensaver;
          recursive = true;
        };
        ".config/sicos/scripts/screensaver.sh" = {
          source = ./scripts/screensaver.sh;
          recursive = true;
        };

        # Elephant files
        ".config/elephant/" = {
          source = ./config-files/elephant;
          recursive = true;
        };

        # Wallpapers
        ".config/sicos/wallpapers" = {
          source = ./wallpapers;
          recursive = true;
        };
      };

      # Enable DankMaterialShell service
      programs.dank-material-shell = lib.mkIf (cfg.shell == "dank-material-shell") {
        enable = true;
        systemd.enable = true;
      };

      # Make DMS settings mutable so we can persist UI changes (like wallpaper)
      # without breaking stylix integration.
      xdg.configFile = lib.mkIf (cfg.shell == "dank-material-shell") {
        "DankMaterialShell/settings.json".force = lib.mkForce true;
      };
      xdg.stateFile = lib.mkIf (cfg.shell == "dank-material-shell") {
        "DankMaterialShell/session.json".force = lib.mkForce true;
      };

      home.activation.make-dms-mutable = lib.mkIf (cfg.shell == "dank-material-shell") (lib.hm.dag.entryAfter ["linkGeneration"] ''
        mkdir -p "$HOME/.config/DankMaterialShell"
        mkdir -p "$HOME/.local/state/DankMaterialShell"
        
        # Handle settings.json
        target="$HOME/.config/DankMaterialShell/settings.json"
        if [ -L "$target" ]; then
          real=$(readlink -f "$target")
          rm "$target"
          if [ -f "$target.backup" ]; then
            # Merge user's backup with Stylix's new theme/fonts
            ${pkgs.jq}/bin/jq -s '.[0] * {
              currentThemeName: .[1].currentThemeName,
              customThemeFile: .[1].customThemeFile,
              fontFamily: .[1].fontFamily,
              monoFontFamily: .[1].monoFontFamily
            }' "$target.backup" "$real" > "$target"
          else
            cp "$real" "$target"
          fi
          chmod 644 "$target"
        elif [ ! -e "$target" ]; then
          echo "{}" > "$target"
          chmod 644 "$target"
        fi

        # Handle session.json
        target="$HOME/.local/state/DankMaterialShell/session.json"
        if [ -L "$target" ]; then
          real=$(readlink -f "$target")
          rm "$target"
          if [ -f "$target.backup" ]; then
            # Merge user's backup (weather info) with Stylix's wallpaper paths
            ${pkgs.jq}/bin/jq -s '.[0] * {
              wallpaperPath: .[1].wallpaperPath,
              wallpaperPathDark: .[1].wallpaperPathDark,
              wallpaperPathLight: .[1].wallpaperPathLight
            }' "$target.backup" "$real" > "$target"
          else
            cp "$real" "$target"
          fi
          chmod 644 "$target"
        elif [ ! -e "$target" ]; then
          echo "{}" > "$target"
          chmod 644 "$target"
        fi
      '');

      # Configure XDG user directories (Downloads, Music, Pictures, etc.)
      # to get proper icons and default directory paths in file managers.
      xdg.userDirs = {
        enable = true;
        createDirectories = true;
      };

      # Kitty terminal emulator special configuration
      programs.kitty = {
        enable = true;
        shellIntegration.enableBashIntegration = true;
        extraConfig = "
            cursor_trail 3
            cursor_trail_decay 0.1 0.4
          ";
      };

      # Btop installation and special configuration for
      # system monitoring
      # It's enable using home manager in order to let
      # Stylix to do its magic and change the theme
      # on the fly
      programs.btop = {
        enable = true;
      };

      # # Fuzzel installation and special configuration for
      # # system monitoring
      # # It's enable using home manager in order to let
      # # Stylix to do its magic and change the theme
      # # on the fly
      # programs.fuzzel = {
      #   enable = true;
      #   settings = {
      #     main = {
      #       use-bold = "yes";
      #       dpi-aware = "no";
      #       hide-before-typing = "yes";
      #       show-actions = "yes";
      #     };
      #   };
      # };

    }))
    (lib.mkIf cfg.theming.enable {
      ########################################
      # Theming with Stylix
      ########################################
      stylix =
        let
          # Base configuration
          commonConfig = {
            enable = true;
            icons = {
              package = pkgs.papirus-icon-theme;
              dark = "Papirus-Dark";
              light = "Papirus";
            };
            fonts =
              let
                monospaceFont = {
                  package = pkgs.nerd-fonts.jetbrains-mono;
                  name = "JetBrainsMono Nerd Font Mono";
                };
              in
              {
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

              zed.enable = true;

              btop.enable = true;

              # fuzzel.enable = true;

              # Waybar theme colors will be built dinamically depending on the
              # scheme defined by the user
              waybar.enable = false;

              dank-material-shell.enable = cfg.shell == "dank-material-shell";

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
            base16Scheme = "${pkgs.base16-schemes}/share/themes/${cfg.theming.base16Scheme}.yaml";
            image = ./wallpapers/fwd-wallhaven-wallhaven-mprye8.jpg;
            cursor = {
              package = pkgs.bibata-cursors;
              name = "Bibata-Modern-Classic";
              size = 24;
            };
          };

          # Light Theme
          lightTheme = commonConfig // {
            polarity = "light";
            base16Scheme = "${pkgs.base16-schemes}/share/themes/${cfg.theming.base16Scheme}.yaml";
            image = ./wallpapers/fwd-wallhaven-wallhaven-v9v3r5.jpg; # Un fondo de pantalla claro
            cursor = {
              package = pkgs.bibata-cursors;
              name = "Bibata-Modern-Ice";
              size = 24;
            };
          };

          # Selecting stylix theming depending on the theme selected by the user
        in
        if cfg.theming.mode == "light" then lightTheme else darkTheme;

      #############################
      # Theming with Home Manager #
      #############################
      # Cursor theming is globally managed by stylix (see above).
      # Explicitly enable pointerCursor config generation in Home Manager.
      home.pointerCursor.enable = true;

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
        gtk4.theme = config.gtk.theme;
      };

      # Set dconf color-scheme preference for GTK4/Adwaita applications
      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = lib.mkForce (if config.stylix.polarity == "dark" then "prefer-dark" else "prefer-light");
        };
      };

      # QT configuration and theming
      qt = {
        enable = true;
        platformTheme.name = "gtk3";
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
