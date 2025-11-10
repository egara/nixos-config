# /home/egarcia/Zero/nixos-config/modules/sicos/hyprland/default.nix
{ config, pkgs, lib, ... }:

let
  cfg = config.programs.sicos.hyprland;
in
{
  # 1. OPTIONS DEFINITION
  options.programs.sicos.hyprland = {
    enable = lib.mkEnableOption "Enable sicos's Hyprland configuration module";

    # Group Hyprland's own config files
    hyprland = {
      configFile = lib.mkOption {
        type = lib.types.path;
        default = ./config-files/hyprland.conf;
        description = "Path to the main hyprland.conf file.";
      };
      bindingsFile = lib.mkOption {
        type = lib.types.path;
        default = ./config-files/bindings.conf;
        description = "Path to the key bindings configuration file for Hyprland.";
      };
      monitorsFile = lib.mkOption {
        type = lib.types.path;
        default = ./config-files/monitors.conf;
        description = "Path to the monitors.conf file.";
      };
      envFile = lib.mkOption {
        type = lib.types.path;
        default = ./config-files/env.conf;
        description = "Path to the env.conf file for environment variables.";
      };
      initFile = lib.mkOption {
        type = lib.types.path;
        default = ./config-files/init.conf;
        description = "Path to the init.conf file for startup applications.";
      };
    };

    # Group lock and idle configs
    hyprlock = {
      configFile = lib.mkOption {
        type = lib.types.path;
        default = ./config-files/hyprlock.conf;
        description = "Path to the hyprlock.conf file.";
      };
      profilePicture = lib.mkOption {
        type = lib.types.path;
        default = ./config-files/egarcia.jpg;
        description = "Path to the profile picture used in the lockscreen.";
      };
    };

    hypridle.configFile = lib.mkOption {
      type = lib.types.path;
      default = ./config-files/hypridle.conf;
      description = "Path to the hypridle.conf file.";
    };

    # Group Waybar configs
    waybar = {
      configFile = lib.mkOption {
        type = lib.types.path;
        default = ./config-files/waybar/config.jsonc;
        description = "Path to the Waybar config.jsonc file.";
      };
      styleFile = lib.mkOption {
        type = lib.types.path;
        default = ./config-files/waybar/style.css;
        description = "Path to the Waybar style.css file.";
      };
      insyncScript = lib.mkOption {
        type = lib.types.path;
        default = ./config-files/waybar/scripts/insync-status.sh;
        description = "Path to the Waybar insync-status.sh script.";
      };
    };

    # Wlogout
    wlogout = {
      layoutFile = lib.mkOption {
        type = lib.types.path;
        default = ./config-files/wlogout/layout;
        description = "Path to the wlogout layout file.";
      };
      styleFile = lib.mkOption {
        type = lib.types.path;
        default = ./config-files/wlogout/style.css;
        description = "Path to the wlogout style.css file.";
      };
      hibernateIcon = lib.mkOption { type = lib.types.path; default = ./config-files/wlogout/icons/hibernate.png; description = "Path to the hibernate icon for the logout screen."; };
      lockIcon = lib.mkOption { type = lib.types.path; default = ./config-files/wlogout/icons/lock.png; description = "Path to the lock icon for the logout screen."; };
      logoutIcon = lib.mkOption { type = lib.types.path; default = ./config-files/wlogout/icons/logout.png; description = "Path to the logout icon for the logout screen."; };
      rebootIcon = lib.mkOption { type = lib.types.path; default = ./config-files/wlogout/icons/reboot.png; description = "Path to the reboot icon for the logout screen."; };
      shutdownIcon = lib.mkOption { type = lib.types.path; default = ./config-files/wlogout/icons/shutdown.png; description = "Path to the shutdown icon for the logout screen."; };
      suspendIcon = lib.mkOption { type = lib.types.path; default = ./config-files/wlogout/icons/suspend.png; description = "Path to the suspend icon for the logout screen."; };
    };

    # Swaync
    swaync = {
      configFile = lib.mkOption {
        type = lib.types.path;
        default = ./config-files/swaync/config.json;
        description = "Path to the swaync config.json file.";
      };
      styleFile = lib.mkOption {
        type = lib.types.path;
        default = ./config-files/swaync/style.css;
        description = "Path to the swaync style.css file.";
      };
    };

    # Swappy
    swappy = {
      configFile = lib.mkOption {
        type = lib.types.path;
        default = ./config-files/swappy/config;
        description = "Path to the swappy config file.";
      };
    };

    # Walker
    walker = {
      configFile = lib.mkOption {
        type = lib.types.path;
        default = ./config-files/walker/config.toml;
        description = "Path to the walker config.toml file.";
      };
    };

    # Group custom scripts
    scripts = {
      changeWallpaper = lib.mkOption { type = lib.types.path; default = ./scripts/change-wallpaper.sh; description = "Path to the script that changes the wallpaper."; };
      disableLaptopScreen = lib.mkOption { type = lib.types.path; default = ./scripts/disable-laptop-screen.sh; description = "Path to the script that disables the laptop screen."; };
      nixosClean = lib.mkOption { type = lib.types.path; default = ./scripts/nixos-clean.sh; description = "Path to the script that cleans the NixOS system."; };
      nixosScripts = lib.mkOption { type = lib.types.path; default = ./scripts/nixos-scripts.sh; description = "Path to a helper script that shows available nixos scripts."; };
      nixosUpdate = lib.mkOption { type = lib.types.path; default = ./scripts/nixos-update.sh; description = "Path to the script that updates the NixOS system."; };
    };

    # Theming
    theming = {
      enable = lib.mkEnableOption "Enable sicos theming";
    };
  };

  # 2. CONFIGURATION (USING THE OPTIONS)
  config = lib.mkIf cfg.enable {
    
    ##########################################
    # Hyprland Environment
    ##########################################

    services = {
      # SDDM
      displayManager = {
        sddm = {
          enable = true;
          wayland.enable = true;
          theme = "catppuccin-mocha-mauve";
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
      
      # Mount, trash, and other functionalities for Thunar
      gvfs.enable = true;

      # Thumbnail support for images
      tumbler.enable = true;

      # Udisks2 to automount USB devices
      udisks2.enable = true;

      dbus.enable = true;
    };

    # Hyprland
    programs.hyprland = {
      enable = true;
      # Using uwsm for initializing Hyprland using systemd
      withUWSM = true; 
      xwayland.enable = true;
    };

    # Thunar File Manager
    programs.thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
    };

    programs.xfconf.enable = true;

    # Walker (Launcher)
    programs.walker.enable = true;

    # Polkit for user authentication
    security.polkit.enable = true;

    # XDG Portal
    xdg.portal = {
      enable = true;
      wlr.enable = lib.mkForce true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    # Waybar overlay for experimental features
    nixpkgs.overlays = [
      (self: super: {
        waybar = super.waybar.overrideAttrs (oldAttrs: {
          mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
        });
      })
    ];

    # Hint Electron apps to use wayland
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    # Add packages required for the Hyprland setup
    environment.systemPackages = with pkgs; [
      # Hyprland and related tools
      hyprland
      hyprlock
      hypridle
      waybar
      hyprland-qtutils
      hyprnome # Workspaces like in GNOME
      wlogout
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
      xwayland
      meson
      wayland-protocols
      wayland-utils
      wlroots

      # App launchers
      libqalculate # For walker

      # Networking
      networkmanagerapplet # GUI for networkmanager

      # Terminal emulator
      kitty

      # Notification daemon
      swaynotificationcenter
      libnotify
      pamixer # For volume control

      # SDDM Theming
      catppuccin-sddm

      # Other tools
      udiskie # Automount USB devices
      swww # for wallpapers
      feh # Image viewer
      grim # Screen capture for Wayland
      slurp # Region selection for grim
      swappy # Screenshot editor
      file-roller # Archive manager for Thunar
      brightnessctl # Screen brightness control
      playerctl # Media player control
      lxqt.lxqt-policykit # Polkit agent
      xfce.catfish # File search GUI
      gnome-calculator # Calculator
      system-config-printer # CUPs GUI
    ];
  };
}
