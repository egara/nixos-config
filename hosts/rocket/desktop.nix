{ config, pkgs, inputs, username, lib, ... }:

{
  ##################################################
  # Special desktop configurations only for Rocket #
  ##################################################

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
}
