{ config, pkgs, inputs, username, lib, ... }:

{
  ##########################################
  # Special configurations only for Rocket #
  # Hyprland                               #
  ##########################################

  networking.hostName = "rocket"; # Define your hostname.

  # Enabling AMD-ATI driver
  boot = {
    initrd = {
      kernelModules = [ "amdgpu" ];
    };
  };

# All the gaming stuff has been commented. Uncomment these lines if needed

#  # Gaming 
#  programs = {
#    # Steam
#    steam = {
#      enable = true;
#      gamescopeSession = {
#        enable = true;
#      };
#    };

#    # Gamemode
#    gamemode = {
#      enable = true;
#    };
#  };

  # SDDM
  services = {
    displayManager = {
      sddm = {
        enable = true;
        wayland = {
          enable = true;
        };
      };
    };

    xserver = {
      enable = true;
      videoDrivers = [ "amdgpu" ];

      xkb = {
        layout = "es";
        variant = "";
      };
    };
  };

  # Swaylock (for locking session)
  security.pam.services.swaylock = {};

#  # List of packages installed in system profile only for rocket host
#  environment.systemPackages = with pkgs; [
#    protonup
#    lutris
#    heroic
#  ];

#  # This is for installing Proton GE
#  # Open a terminal and execute: protonup -d "~/.steam/root/compatibilitytools.d/"
#  # For more information: https://www.youtube.com/watch?v=qlfm3MEbqYA
#  # and https://github.com/vimjoyer/nixos-gaming-video

  # Modules
  imports = [
    # Hyprland common module
    ../../../../modules/desktop/hyprland.nix
  ];

}
