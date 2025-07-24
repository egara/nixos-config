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

let
  # Github repository for yazi plugins https://github.com/yazi-rs/plugins
  yazi-plugins = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "main";
    hash = "sha256-4p+VXUr76kC/dyJZzzkCwNGEUV53YYZ3tYoFpsKboU0=";
  };

in {
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

    # QMMP winamp skin
    # If QMMP doesn't switch to Winamp skin automatically, go to Edit -> Settings -> Plugins and check
    # Skinned User Interface within User Interfaces section. Then, restart QMMP
    file.".config/qmmp/skins/winamp_classic.wsz".source = ../home-manager/qmmp/skins/winamp_classic.wsz;    

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

  # Yazi special configuration. This package won't be needed to be specifically installed
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";

    # yazi.toml
    settings = {
      opener.play = [
        { run = "qmmp \"$@\""; orphan= true; for = "unix"; }
      ];      
    };

    plugins = {
      full-border = "${yazi-plugins}/full-border.yazi";
      toggle-pane = "${yazi-plugins}/toggle-pane.yazi";
      mount = "${yazi-plugins}/mount.yazi";
    };

    # Some plugins need to be loaded before hand.
    # Example: full-border https://github.com/yazi-rs/plugins/tree/main/full-border.yazi
    initLua = ''
      require("full-border"):setup()
    '';

    # keymap.toml
    keymap = {
      manager.prepend_keymap = [
        {
          on = "T";
          run = "plugin toggle-pane max-preview";
          desc = "Maximize or restore the preview pane";
        }
        {
          on = "M";
          run = "plugin mount";
          desc = "Mount and manage USB devices";
        }
        {
          on = [ "g" "u" ];
          run = "cd /run/media/egarcia";
          desc = "USB";
        }
        {
          on = "y";
          for  = "unix";
          run = ["shell -- for path in \"$@\"; do echo \"file://$path\"; done | wl-copy -t text/uri-list" "yank"];
          desc = "Copy a file both in system and yazi clipboard";
        }
        {
          on = "!";
          for  = "unix";
          run = ["shell \"$SHELL\" --block"];
          desc = "Open $SHELL here";
        }
      ];
    };
  };

  # Virtual Manager special configuration (https://nixos.wiki/wiki/Virt-manager)
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

}