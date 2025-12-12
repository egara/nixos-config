{ config, pkgs, pkgs-stable, ... }:

{
  ###########################################
  # Special configurations only for Ironman #
  ###########################################

  # Hostname
  networking.hostName = "ironman";

  # Video drivers for xserver
  services = {
    xserver = {
      videoDrivers = [ "nvidia" ];
    };
  };

  # Global power management for laptops
  powerManagement.enable = true;

  # Changing TLP to power profiles daemon for adjusting the
  # laptop performance
  # This service is enabled in its own module
  # nixos-config/modules/custom/power-management.nix
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

  # Important: There is a problem related to the hardware of this
  # machine and the version of the kernel. Due to some incompatibilities
  # related to the GPU and CPU of this machine
  # CPU: Intel® Core™ i7 6700HQ - 4C/8T
  # GPU: Nvidia GTX 960M 2GB GDDR5 + Intel i915 (Skylake)
  # the highest version of the kernel supported is 6.4 so
  # it is necessary to let the laptop booting normally, select
  # a kernel lower than 6.4
  boot.kernelPackages = pkgs.linuxPackages_6_1;
  #boot.kernelPackages = pkgs.linuxPackages_latest;
  #boot.kernelPackages = pkgs.linuxPackages_zen;

  # Kernel parameters passed in GRUB in order to
  # allow the laptop starts normally due to the 
  # hardware of this machine
   boot.kernelParams = [ 
     "i915.enable_rc6=0" 
     "pcie_port_pm=off" 
     "acpi_osi=\"!Windows 2015\""
   ];

  # Enabling Nvidia driver for Docker
  hardware.nvidia-container-toolkit = {
    enable = true;
  };

  # The current docker version is now working fine with Nvidia drivers
  virtualisation.docker.package = pkgs.docker;
  #virtualisation.docker.package = pkgs.docker_25;

  # Above is the way to do this finally but meanwhile 
  # it will be used the deprecated way. In order to 
  # activate the new way of doing this uncomment the lines
  # above and comment the lines below. Docker version
  # is pointing to 25 because currently, the last version 
  # 27 is not working properly with the NVIDIA drivers
  # More information:
  # https://www.reddit.com/r/NixOS/comments/16d94ut/using_containers_for_python_c/
  # https://github.com/NixOS/nixpkgs/issues/322400
  #virtualisation.docker = {
  #  enableNvidia = true;
  #};

  # Nvidia hybrid grafics configuration
  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

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

  # Special environment variables for allowing new GTK applications in
  # a hybrid system (with two graphics cards like this laptop)
  # https://github.com/NixOS/nixpkgs/issues/359069
  environment.variables = {
    GSK_RENDERER = "ngl";
  };

  # Bluetooth support and management
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
  services.blueman.enable = true;

  # List of packages installed in system profile only for this host
  environment.systemPackages = with pkgs; [
    bluez-tools
    pkgs-stable.jetbrains.pycharm-community-bin
    #python312Packages.pyqt5
    #python312Packages.pyyaml
    #python312Packages.sip
    #python312Packages.tkinter
    eclipses.eclipse-jee
    #jdk8
    #jdk17
    teams-for-linux
  ];
}
