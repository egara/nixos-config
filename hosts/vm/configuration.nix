{ pkgs, ... }:

{
  ######################################
  # Special configurations only for VM #
  ######################################

  networking.hostName = "experimental"; # Define your hostname.
  
  # Spice guest additions for QEMU
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
}