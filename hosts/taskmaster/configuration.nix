{ config, pkgs, pkgs-stable, ... }:

{
  ##############################################
  # Special configurations only for taskmaster #
  ##############################################

  # Networking configuration
  networking = {
    # Hostname
    hostName = "taskmaster";

    # Static IP address (v4)
    interfaces = {
      enp0s31f6 = {
        useDHCP = false;
        ipv4 = {
          addresses = [
            {
              address = "10.18.8.82";
              prefixLength = 24;
            }
          ];
        };
      };
    };

    # Gateway
    defaultGateway = "10.18.8.1";
    # DNS
    nameservers = [ "193.146.97.133" "193.146.97.132" ];
  };
  
  # Global power management for laptops
  powerManagement.enable = true;

  # Changing TLP to power profiles daemon for adjusting the
  # laptop performance
  # This service is enabled via sicos module if it's desired
  # services.power-profiles-daemon.enable = true;

  # # TLP
  # services.tlp = {
  #   enable = true;
  #   settings = {
  #     CPU_SCALING_GOVERNOR_ON_AC = "performance";
  #     CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

  #     CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
  #     CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

  #     CPU_MIN_PERF_ON_AC = 0;
  #     CPU_MAX_PERF_ON_AC = 100;
  #     CPU_MIN_PERF_ON_BAT = 0;
  #     CPU_MAX_PERF_ON_BAT = 20;

  #     # Optional helps save long term battery health
  #     # START_CHARGE_THRESH_BAT0 = 40; # 40 and bellow it starts to charge
  #     # STOP_CHARGE_THRESH_BAT0 = 90; # 90 and above it stops charging
  #   };
  # }; 

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
      apache-directory-studio
      eclipses.eclipse-jee
      pkgs-stable.jdk8  
  ];

  # Creating a symlink for openjdk8 in order to configure Eclipse properly
  systemd.tmpfiles.rules = [
    "L /var/lib/jvm/openjdk8 - - - - ${pkgs-stable.jdk8}/lib/openjdk"
  ];
}
