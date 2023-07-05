#
#  General Home-manager configuration
#
#  flake.nix
#   ├─ ./hosts
#   │   └─ home.nix *
#   └─ ./modules
#       ├─ ./programs
#       │   └─ default.nix
#       └─ ./services
#           └─ default.nix
#

{ config, lib, pkgs, username, ... }:

{ 
  #imports =
    # Home Manager Modules
    #(import ../modules/programs) ++
    #(import ../modules/services);

  home = {
    username = "${username}";
    homeDirectory = "/home/${username}";
    stateVersion = "22.05";
    packages = with pkgs; [
      # Command line applications
      htop
      yadm
      ansible
      git
      curl
      wget
      cheat
      gcc
      gnumake

      # Video/Audio
      #feh               # Image Viewer
      #mpv               # Media Player
      #pavucontrol       # Audio Control
      #plex-media-player # Media Player
      #vlc               # Media Player
      #stremio           # Media Streamer

      # Apps
      #appimage-run      # Runs AppImages on NixOS
      #firefox           # Browser
      #google-chrome     # Browser
      #remmina           # XRDP & VNC Client

      # File Management
      #gnome.file-roller # Archive Manager
      #okular            # PDF Viewer
      #pcmanfm           # File Manager
      #rsync             # Syncer - $ rsync -r dir1/ dir2/

      # General configuration
      #killall          # Stop Applications
      #pciutils         # Computer Utility Info
      #usbutils         # USB Utility Info
      #wacomtablet      # Wacom Tablet
      #zsh              # Shell
      #
      # General home-manager
      #alacritty        # Terminal Emulator
      #dunst            # Notifications
      #doom emacs       # Text Editor
      #libnotify        # Dependency for Dunst
      #neovim           # Text Editor
      #rofi             # Menu
      #rofi-power-menu  # Power Menu
      #udiskie          # Auto Mounting
      #vim              # Text Editor
      #
      # Xorg configuration
      #xclip            # Console Clipboard
      #xorg.xev         # Input Viewer
      #xorg.xkill       # Kill Applications
      #xorg.xrandr      # Screen Settings
      #xterm            # Terminal
      #
      # Xorg home-manager
      #flameshot        # Screenshot
      #picom            # Compositer
      #sxhkd            # Shortcuts
      #
      # Wayland configuration
      #autotiling       # Tiling Script
      #grim             # Image Grabber
      #slurp            # Region Selector
      #swappy           # Screenshot Editor
      #swayidle         # Idle Management Daemon
      #wev              # Input Viewer
      #wl-clipboard     # Console Clipboard
      #wlr-randr        # Screen Settings
      #xwayland         # X for Wayland
      #
      # Wayland home-manager
      #mpvpaper         # Video Wallpaper
      #pamixer          # Pulse Audio Mixer
      #swaybg           # Background
      #swaylock-fancy   # Screen Locker
      #waybar           # Bar
      #
      # Desktop
      #ansible          # Automation
      #blueman          # Bluetooth
      #deluge           # Torrents
      #discord          # Chat
      #ffmpeg           # Video Support (dslr)
      #gmtp             # Mount MTP (GoPro)
      #gphoto2          # Digital Photography
      #handbrake        # Encoder
      #heroic           # Game Launcher
      #hugo             # Static Website Builder
      #lutris           # Game Launcher
      #mkvtoolnix       # Matroska Tool
      #plex-media-player# Media Player
      #prismlauncher    # MC Launcher
      #steam            # Games
      #simple-scan      # Scanning
      #sshpass          # Ansible dependency
      # 
      # Laptop
      #cbatticon        # Battery Notifications
      #blueman          # Bluetooth
      #light            # Display Brightness
      #libreoffice      # Office Tools
      #simple-scan      # Scanning
      #
      # Flatpak
      #obs-studio       # Recording/Live Streaming
    ];
    #file.".config/wall".source = ../modules/themes/wall;
    #file.".config/wall.mp4".source = ../modules/themes/wall.mp4;
    #pointerCursor = {                         # This will set cursor system-wide so applications can not choose their own
    #  gtk.enable = true;
    #  name = "Dracula-cursors";
    #  #name = "Catppuccin-Mocha-Dark-Cursors";
    #  package = pkgs.dracula-theme;
    #  #package = pkgs.catppuccin-cursors.mochaDark;
    #  size = 16;
    #};
    #stateVersion = "22.05";
  };

  programs = {
    home-manager.enable = true;
  };
}
