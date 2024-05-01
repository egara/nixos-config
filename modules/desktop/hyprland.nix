{ config, pkgs, inputs, username, ... }:

{
  ##########################################
  # Hyprland                               #
  ##########################################

  # Hyprland
  programs.hyprland = {
    enable = true; 
    xwayland.enable = true;
  };

  # Hint Electron apps to use wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  services.dbus.enable = true;
  xdg.portal = {
    enable = true;
    wlr.enable = true;
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

  # Fonts
  fonts.packages = with pkgs; [
    font-awesome
    nerdfonts
    meslo-lgs-nf
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
  ];

  # SDDM theming
  services.displayManager.sddm.theme = "Elegant";

  # Udisks2 to automount USB devices
  services.udisks2.enable = true;

  # Thunar (Part 1)
  programs = {
    thunar = {
      enable = true;
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
      hyprland
      wlogout
      waybar
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
      xwayland
      meson
      wayland-protocols
      wayland-utils
      wl-clipboard
      wlroots
      pipewire
      ###############
      # app-launchers
      ###############
      wofi
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
      swaylock
      swayidle
      #########
      # Theming
      #########
      elegant-sddm
      #rose-pine-gtk-theme
      #moka-icon-theme
      #############
      # Other tools
      #############
      udiskie # Automount USB devices
      swww # for wallpapers
      feh # Image viewer
      #kdePackages.dolphin

  ];
}