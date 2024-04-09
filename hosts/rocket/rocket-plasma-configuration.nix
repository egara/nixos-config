{ config, pkgs, inputs, username, ... }:

{
  ##########################################
  # Special configurations only for Rocket #
  # Plasma 6                               #
  ##########################################

  networking.hostName = "rocket"; # Define your hostname.

  # Enabling AMD-ATI driver
  boot = {
    initrd = {
      kernelModules = [ "amdgpu" ];
    };
  };

  # Desktop Environment
  # Plasma 6 and SDDM
  services = {
    xserver = {
      enable = true;
      videoDrivers = [ "amdgpu" ];
      layout = "es";
      xkbVariant = "";
      displayManager = {
        defaultSession = "plasma";
        sddm = {
          enable = true;
          wayland = {
            enable = true;
          };
        };
      };

      # Plasma 5
      #desktopManager.plasma5.enable = true;
      # Plasma 6
      desktopManager.plasma6.enable = true;
    };
  };

  # List of packages installed in system profile related to Plasma 6
  environment.systemPackages = with pkgs; [
      kdePackages.okular
      konsave
  ];
}
