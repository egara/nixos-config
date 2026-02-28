# /home/egarcia/Zero/nixos-config/modules/sicos/hyprland/default.nix
{ config, pkgs, lib, sicos-source-path, ... }:

let
  cfg = config.programs.sicos.hyprland;
  sddm-theme-sicos = pkgs.callPackage ./sddm-theme {};
in
{
  # 1. OPTIONS DEFINITION
  options.programs.sicos.hyprland = {
    enable = lib.mkEnableOption "Enable sicos's Hyprland configuration module";

    # Group Hyprland's own config files
    hyprland = {
      configFile = lib.mkOption {
        type = lib.types.path;
        # Default config file will depend on if kanshi is
        # enabled or disabled by the user
        # default = "${sicos-source-path}/modules/sicos/hyprland/config-files/hyprland.conf";
        description = "Path to hyprland.conf file.";
      };
    };

    # Group lock and idle configs
    hyprlock = {
      configFile = lib.mkOption {
        type = lib.types.path;
        default = "${sicos-source-path}/modules/sicos/hyprland/config-files/hyprlock.conf";
        description = "Path to the hyprlock.conf file.";
      };
      profilePicture = lib.mkOption {
        type = lib.types.path;
        default = "${sicos-source-path}/modules/sicos/hyprland/config-files/user.jpg";
        description = "Path to the profile picture used in the lockscreen.";
      };
    };

    hypridle.configFile = lib.mkOption {
      type = lib.types.path;
      default = "${sicos-source-path}/modules/sicos/hyprland/config-files/hypridle.conf";
      description = "Path to the hypridle.conf file.";
    };

    # Group Waybar configs
    waybar = {
      overwrite = lib.mkEnableOption "Overwrite waybar configurations. If it is set to true, then configFile and styleFile MUST be provided by the user.";
      default = false;

      configFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the Waybar config.jsonc file.";
      };
      styleFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the Waybar style.css file.";
      };
    };

    # Wlogout
    wlogout = {
      overwrite = lib.mkEnableOption "Overwrite wlogout configurations. If it is set to true, then styleFile MUST be provided by the user.";
      default = false;
      layoutFile = lib.mkOption {
        type = lib.types.path;
        default = "${sicos-source-path}/modules/sicos/hyprland/config-files/wlogout/layout";
        description = "Path to the wlogout layout file.";
      };
      styleFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the wlogout style.css file.";
      };
      hibernateIcon = lib.mkOption { type = lib.types.path; default = "${sicos-source-path}/modules/sicos/hyprland/config-files/wlogout/icons/hibernate.png"; description = "Path to the hibernate icon for the logout screen."; };
      lockIcon = lib.mkOption { type = lib.types.path; default = "${sicos-source-path}/modules/sicos/hyprland/config-files/wlogout/icons/lock.png"; description = "Path to the lock icon for the logout screen."; };
      logoutIcon = lib.mkOption { type = lib.types.path; default = "${sicos-source-path}/modules/sicos/hyprland/config-files/wlogout/icons/logout.png"; description = "Path to the logout icon for the logout screen."; };
      rebootIcon = lib.mkOption { type = lib.types.path; default = "${sicos-source-path}/modules/sicos/hyprland/config-files/wlogout/icons/reboot.png"; description = "Path to the reboot icon for the logout screen."; };
      shutdownIcon = lib.mkOption { type = lib.types.path; default = "${sicos-source-path}/modules/sicos/hyprland/config-files/wlogout/icons/shutdown.png"; description = "Path to the shutdown icon for the logout screen."; };
      suspendIcon = lib.mkOption { type = lib.types.path; default = "${sicos-source-path}/modules/sicos/hyprland/config-files/wlogout/icons/suspend.png"; description = "Path to the suspend icon for the logout screen."; };
    };

    # Swaync
    swaync = {
      overwrite = lib.mkEnableOption "Overwrite swaync configurations. If it is set to true, then configFile and styleFile MUST be provided by the user.";
      default = false;

      configFile = lib.mkOption {
        type = lib.types.path;
        default = "${sicos-source-path}/modules/sicos/hyprland/config-files/swaync/config.json";
        description = "Path to the swaync config.json file.";
      };
      styleFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the swaync style.css file.";
      };
    };

    # Kanshi
    kanshi = {
      enable = lib.mkEnableOption "Enable Kanshi integration for automated monitors layout switching.";
      default = false;
      configFile = lib.mkOption {
        type = lib.types.path;
        default = "${sicos-source-path}/modules/sicos/hyprland/config-files/kanshi/config";
        description = "Path to the kanshi config file.";
      };
    };



    # Custom scripts
    scripts = {
      path = lib.mkOption {
        type = lib.types.path;
        default = "${sicos-source-path}/modules/sicos/hyprland/scripts/";
        description = "Path where all the scripts are located.";
      };
    };

    # Theming
    theming = {
      enable = lib.mkEnableOption "Enable sicos theming";
      default = true;

      mode = lib.mkOption {
        type = lib.types.enum [ "dark" "light" ];
        default = "dark";
        description = "Set the theme mode for the system.";
      };

      base16Scheme = lib.mkOption {
        type = lib.types.str;
        default = "catppuccin-mocha";
        description = "Set the base16 scheme for Stylix.";
      };
    };

    # Power Management using power profiles daemon
    powerManagement = {
      enable = lib.mkEnableOption "Enable sicos's power management configuration";
      default = true;
    };

    # Insync integration
    insync = {
      enable = lib.mkEnableOption "Enable Insync and its Waybar integration.";
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.insync;
        description = "The Insync package to use.";
      };
    };
  };

  imports = [
    ./power-management.nix
    ./insync-integration.nix
  ];

  disabledModules = [ "services/misc/elephant.nix" ];

  # 2. CONFIGURATION (USING THE OPTIONS)
  config = lib.mkIf cfg.enable {

      #####################
      # Hyprland defaults #
      #####################
      programs.sicos.hyprland.hyprland.configFile = lib.mkDefault (
        if config.programs.sicos.hyprland.kanshi.enable then
            "${sicos-source-path}/modules/sicos/hyprland/config-files/hyprland-with-kanshi.conf"
        else
            "${sicos-source-path}/modules/sicos/hyprland/config-files/hyprland-without-kanshi.conf"
      );



      ##########################################
      # Hyprland Environment
      ##########################################

      services = {
        # SDDM
        displayManager = {
          sddm = {
            enable = lib.mkForce true;
            wayland.enable = true;
            theme = "sicos";
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
        plugins = with pkgs; [
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
        sddm-theme-sicos

        # Other tools
        udiskie # Automount USB devices
        swww # for wallpapers
        feh # Image viewer
        hyprshot # Screenshots tool
        satty # Screenshot editor
        file-roller # Archive manager for Thunar
        brightnessctl # Screen brightness control
        playerctl # Media player control
        lxqt.lxqt-policykit # Polkit agent
        catfish # File search GUI
        gnome-calculator # Calculator
        system-config-printer # CUPs GUI
        vlc # For volume up/down popping sound

        # Tools for the screensaver
        terminaltexteffects
        jq
        socat
        libinput
      ];
    };
}
