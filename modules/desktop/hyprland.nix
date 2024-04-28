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

  # Thunar
  programs = {
    thunar = {
      enable = true;
    };

    xfconf = {
      enable = true;
    };

  };
  services.gvfs.enable = true; # Mount, trash, and other functionalities
  services.tumbler.enable = true; # Thumbnail support for images

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
      kdePackages.qt6ct # QT theming configurator
      kdePackages.breeze
      kdePackages.breeze-icons
      kdePackages.breeze-gtk
      adwaita-qt6
      gnome.adwaita-icon-theme
      kdePackages.qtwayland
      yaru-theme
      #############
      # Other tools
      #############
      udiskie # Automount USB devices
      swww # for wallpapers
      kdePackages.dolphin

  ];
}