{ config, pkgs, inputs, username, lib, ... }:

{
  ###########################################
  # Special configurations only for Ironman #
  # Hyprland                                #
  ###########################################

  networking.hostName = "ironman"; # Define your hostname.

  # Enabling NVIDIA driver
  boot = {
    initrd = {
      kernelModules = [ "i915" ];
    };

    # Blacklist the proprietary NVIDIA driver, if needed
    blacklistedKernelModules = [ "nvidia" "nvidia_uvm" "nvidia_drm" "nvidia_modeset" "nouveau" ];
  };

  # Kernel parameters passed in GRUB
  boot.kernelParams = [ 
    "i915.enable_rc6=0" 
    "pcie_port_pm=off" 
    "acpi_osi=\"!Windows 2015\""
    "mem_sleep_default=deep"
    "nvme.noacpi=1"
    "i915.enable_psr=1"
  ];

  # Hybrid grafics configuration
#  hardware.nvidia.modesetting.enable = true;
#  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.production;
#  hardware.nvidia.prime = {
#    offload = {
#      enable = true;
#      enableOffloadCmd = true;
#    };

#    # integrated
#    intelBusId = "PCI:0:2:0";
        
#    # dedicated
#    nvidiaBusId = "PCI:1:0:0";
#  };

  environment.variables = {
      VDPAU_DRIVER = lib.mkIf config.hardware.opengl.enable (lib.mkDefault "va_gl");
  };
  
  hardware.opengl.extraPackages = with pkgs; [
    vaapiIntel
    libvdpau-va-gl
    intel-media-driver
  ];

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
      #videoDrivers = [ "nouveau" ];

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
