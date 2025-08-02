{ config, pkgs, inputs, username, lib, ... }:

{
  ###########################################
  # Special configurations only for Rocket  #
  ###########################################
  
  networking.hostName = "rocket"; # Define your hostname.

  # Enabling AMD-ATI driver
  boot = {
    initrd = {
      kernelModules = [ "amdgpu" ];
    };
  };

  # Use the latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # List of packages installed in system profile only for this host
  environment.systemPackages = with pkgs; [
  ];
}