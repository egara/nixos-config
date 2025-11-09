# /home/egarcia/Zero/nixos-config/modules/sicos/hyprland/hm-module.nix
{ config, pkgs, lib, nixosConfig, ... }:

let
  cfg = nixosConfig.programs.sicos.hyprland;
in
{
  # This is a home-manager module.
  # It's imported into a user's home-manager configuration.
  config = lib.mkIf cfg.enable {
    home.file = {
      # Hyprland files
      ".config/hypr/hyprland.conf".source = cfg.hyprland.configFile;
      ".config/hypr/bindings.conf".source = cfg.hyprland.bindingsFile;
      ".config/hypr/monitors.conf".source = cfg.hyprland.monitorsFile;
      ".config/hypr/env.conf".source = cfg.hyprland.envFile;
      ".config/hypr/init.conf".source = cfg.hyprland.initFile;

      # Hyprlock files
      ".config/hypr/hyprlock.conf".source = cfg.hyprlock.configFile;
      ".config/hypr/egarcia.jpg".source = cfg.hyprlock.profilePicture;

      # Hypridle file
      ".config/hypr/hypridle.conf".source = cfg.hypridle.configFile;

      # Waybar files
      ".config/waybar/config.jsonc".source = cfg.waybar.configFile;
      ".config/waybar/style.css".source = cfg.waybar.styleFile;
      ".config/waybar/scripts/insync-status.sh".source = cfg.waybar.insyncScript;

      # Wlogout files
      ".config/wlogout/layout".source = cfg.wlogout.layoutFile;
      ".config/wlogout/style.css".source = cfg.wlogout.styleFile;
      ".config/wlogout/icons/hibernate.png".source = cfg.wlogout.hibernateIcon;
      ".config/wlogout/icons/lock.png".source = cfg.wlogout.lockIcon;
      ".config/wlogout/icons/logout.png".source = cfg.wlogout.logoutIcon;
      ".config/wlogout/icons/reboot.png".source = cfg.wlogout.rebootIcon;
      ".config/wlogout/icons/shutdown.png".source = cfg.wlogout.shutdownIcon;
      ".config/wlogout/icons/suspend.png".source = cfg.wlogout.suspendIcon;

      # Swaync files
      ".config/swaync/config.json".source = cfg.swaync.configFile;
      ".config/swaync/style.css".source = cfg.swaync.styleFile;

      # Swappy file
      ".config/swappy/config".source = cfg.swappy.configFile;

      # Walker file
      ".config/walker/config.toml".source = cfg.walker.configFile;

      # Scripts (marked as executable)
      ".config/hypr/change-wallpaper.sh" = { source = cfg.scripts.changeWallpaper; executable = true; };
      ".config/hypr/disable-laptop-screen.sh" = { source = cfg.scripts.disableLaptopScreen; executable = true; };
      ".config/hypr/nixos-clean.sh" = { source = cfg.scripts.nixosClean; executable = true; };
      ".config/hypr/nixos-scripts.sh" = { source = cfg.scripts.nixosScripts; executable = true; };
      ".config/hypr/nixos-update.sh" = { source = cfg.scripts.nixosUpdate; executable = true; };
    };

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

    # Kanshi (multi monitoring layout management)
    services.kanshi = {
      enable = true;
      systemdTarget = "hyprland-session.target";
      settings = [
        {
          profile = {
            name = "home";
            outputs = [
              { criteria = "eDP-1"; scale = 1.0; status = "enable"; mode = "1920x1080"; position = "1920,0"; }
              { criteria = "HDMI-A-2"; scale = 1.0; status = "enable"; mode = "1920x1080"; position = "0,0"; }
            ];
          };
        }
        {
          profile = {
            name = "office";
            outputs = [
              { criteria = "DP-2"; scale = 1.0; status = "enable"; mode = "1920x1080"; position = "0,0"; }
              { criteria = "DP-1"; scale = 1.0; status = "enable"; mode = "1920x1080"; position = "1920,0"; }
              { criteria = "eDP-1"; status = "disable"; }
            ];
          };
        }
        {
          profile = {
            name = "meeting-room";
            outputs = [
              { criteria = "DP-2"; scale = 1.0; status = "enable"; mode = "1920x1080"; position = "0,0"; }
              { criteria = "eDP-1"; scale = 1.0; status = "enable"; mode = "1920x1080"; position = "1920,0"; }
            ];
          };
        }
        {
          profile = {
            name = "undocked";
            outputs = [ { criteria = "eDP-1"; scale = 1.0; status = "enable"; mode = "1920x1080"; position = "0,0"; } ];
          };
        }
      ];
    };
  };
}
