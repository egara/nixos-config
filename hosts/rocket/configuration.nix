{ config, pkgs, inputs, username, lib, ... }:

{
  ###########################################
  # Special configurations only for Rocket  #
  ###########################################
  
  # Hostname
  networking.hostName = "rocket";

  # Enabling AMD-ATI driver
  boot = {
    initrd = {
      kernelModules = [ "amdgpu" ];
    };
  };

  # Video drivers for xserver
  services = {
    xserver = {
      videoDrivers = [ "amdgpu" ];
    };
  };
  
  # Use the latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # List of packages installed in system profile only for this host
  environment.systemPackages = with pkgs; [
  ];
}