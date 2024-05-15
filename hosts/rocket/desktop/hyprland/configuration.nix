{ config, pkgs, inputs, username, ... }:

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

  # Enabling virtualization KVM-QUEMU and Virtual Manager
  virtualisation = {
    libvirtd = {
      enable = true;
    };
  };
  programs = {
    virt-manager = {
      enable = true;
    };
  };

  # Modules
  imports = [
    # Hyprland common module
    ../../../../modules/desktop/hyprland.nix
  ];

}
