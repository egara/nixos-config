{ config, pkgs, pkgs-stable, ... }:

{
  ###########################################
  # Special configurations only for strange #
  ###########################################

  # Networking configuration
  networking = {
    # Hostname
    hostName = "strange";
  };
  
  # Enabling BIOS updates for Framework Laptop 13
  services.fwupd.enable = true;

  # Global power management for laptops
  powerManagement.enable = true;

  # Thermald proactively prevents overheating on Intel CPUs and works well with other tools
  services.thermald.enable = true;

  # Special behaviours
  services.logind = {
    settings = {
      Login = {
        # When laptop lid is closed
        HandleLidSwitch = "suspend";
        # When power button is pushed
        HandlePowerKey = "suspend";
      };
    };    
  }; 

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # Kernel parameters passed in GRUB in order to
  # allow the laptop starts normally due to the 
  # hardware of this machine
   boot.kernelParams = [ 
   ];

  # Docker
  virtualisation.docker.package = pkgs.docker;

  # Bluetooth support and management
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
  services.blueman.enable = true;

  # List of packages installed in system profile only for this host
  environment.systemPackages = with pkgs; [
      #apache-directory-studio
      #eclipses.eclipse-jee
      #pkgs-stable.jdk8  
  ];
}
