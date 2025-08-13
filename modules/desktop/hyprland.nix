{ pkgs, lib, ... }:

{
  ##########################################
  # Hyprland                               #
  ##########################################

  services = {
    # SDDM
    displayManager = {
      sddm = {
        enable = true;
        wayland = {
          enable = true;
        };
        theme = "Elegant";
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
  };

  # Hyprland
  programs.hyprland = {
    enable = true;
    # Using uwsm for initializing Hyprland using systemd and allowing to
    # run every long term application (walker, waybar...) wraping them
    # within systemd units automatically
    # More info: https://www.reddit.com/r/hyprland/comments/1k9vwfy/what_is_this_uwsm_with_hyprland/?tl=es-es
    # https://www.youtube.com/watch?v=XmwC9qV7lKs
    withUWSM = true; 
    xwayland.enable = true;
    # Overwriting the default hyprland packages to the last version available on GitHub
    # hyprland input is defined in flake.nix
    # package = inputs.hyprland.packages."${pkgs.system}".hyprland;
  };

  # Hint Electron apps to use wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  services.dbus.enable = true;
  xdg.portal = {
    enable = true;
    wlr.enable = lib.mkForce true;  # Forcefully set wlr.enable to true
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  nixpkgs.overlays = [
    (self: super: {
      waybar = super.waybar.overrideAttrs (oldAttrs: {
        mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
      });
    })
  ];

  # Udisks2 to automount USB devices
  services.udisks2.enable = true;

  # Thunar (Part 1)
  programs = {
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
    };

    xfconf = {
      enable = true;
    };

  };

  # Thunar (Part 2)
  services = {
    # Mount, trash, and other functionalities
    gvfs = {
      enable = true;
    };

    # Thumbnail support for images
    tumbler = {
      enable = true;
    };
  };

  ##########
  # Polkit #
  ##########
  # Enabling Polkit for user authentication using grpahical applications
  security = {
    polkit = {
      enable = true;
    };
  };

  # Udev rules
  # USB plugin and eject notifications (actually this is not needed because udiskie always notifies)
  # For more information about it: https://askubuntu.com/questions/949331/how-to-set-rule-only-for-usb-flash-drives-in-rules-d
  #services.udev.extraRules = ''
  #  ACTION=="add", SUBSYSTEM=="usb",ENV{ID_TYPE}=="disk", ENV{ID_USB_DRIVER}=="usb-storage",RUN+="${pkgs.dunst}/bin/dunstify -a 'USB' -u low 'A new USB device has been connected'"
  #  ACTION=="remove", SUBSYSTEM=="usb",ENV{ID_TYPE}=="disk",ENV{ID_USB_DRIVER}=="usb-storage",RUN+="${pkgs.dunst}/bin/dunstify -a 'USB' -u low 'USB device has been desconnected'"
  #'';

  # List of packages installed in system profile related to Hyprland
  environment.systemPackages = with pkgs; [
      ##################################
      # Packages for supporting Hyprland
      ##################################
      #hyprland
      hyprland-qtutils
      hyprnome # Workspaces like in GNOME
      #hyprlandPlugins.hyprbars
      #hyprlandPlugins.hyprexpo
      wlogout
      waybar
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
      xwayland
      meson
      wayland-protocols
      wayland-utils
      wlroots
      #inputs.hyprswitch.packages.x86_64-linux.default # Window switcher for Hyprland installed from a flake (see flake.nix configuration file for more information)
      ###############
      # app-launchers
      ###############
      #wofi
      walker
      libqalculate
      ############
      # networking
      ############
      networkmanagerapplet # GUI for networkmanager
      ###################
      # terminal emulator
      ###################
      kitty
      #####################
      # notification daemon
      #####################
      dunst
      libnotify
      pamixer # For getting the volume via command line and integrate it with dunst and hyprland
      #########################
      # System locking and IDLE
      #########################
      swaylock-effects
      swayidle
      #########
      # Theming
      #########
      elegant-sddm
      #####################
      # clipboard
      #####################
      cliphist
      #############
      # Other tools
      #############
      udiskie # Automount USB devices
      swww # for wallpapers
      feh # Image viewer
      grim # Screen capture for Wayland. It depends on slurp
      slurp # Allows to select a region in Wayland
      file-roller # Allows to extract files directly using Thunar
      brightnessctl # For incresing or decreasing the screen brightness
      playerctl # For managing media players via command line (it will be used to integrate these functionalities in waybar)
      lxqt.lxqt-policykit # For bring up dialogs to let the user authenticate
      xfce.catfish # For searching files via GUI (Thunar doesn't provide anything like this)
  ];
}