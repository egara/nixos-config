{ config, pkgs, inputs, username, lib, ... }:

{
  ###########################################
  # Special configurations only for Ironman #
  # Hyprland                                #
  ###########################################

  networking.hostName = "ironman"; # Define your hostname.

#  # Enabling NVIDIA driver
#  boot = {
#    initrd = {
#      kernelModules = [ "nvidia" ];
#    };
#  };

  # Kernel parameters passed in GRUB
  boot.kernelParams = [ 
    "i915.enable_rc6=0" 
    "pcie_port_pm=off" 
    "acpi_osi=\"!Windows 2015\""
  ];

  # Hybrid grafics configuration
  hardware.nvidia.prime = {
    offload = {
      enable = true;
      enableOffloadCmd = true;
    };

    # integrated
    intelBusId = "PCI:0:2:0";
        
    # dedicated
    nvidiaBusId = "PCI:1:0:0";
  };

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
      videoDrivers = [ "nvidia" ];

      xkb = {
        layout = "es";
        variant = "";
      };
    };
  };

  # Swaylock (for locking session)
  security.pam.services.swaylock = {};

  # List of packages installed in system profile only for this host
  environment.systemPackages = with pkgs; [
    glxinfo
  ];

  # Modules
  imports = [
    # Hyprland common module
    ../../../../modules/desktop/hyprland.nix
  ];

}
