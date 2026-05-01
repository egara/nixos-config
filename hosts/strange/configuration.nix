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

  # Changing TLP to power profiles daemon for adjusting the
  # laptop performance
  # It is commented because the Framework flake enabled includes this
  # configuration and TLP is not recommended for AMD AI processors
  # services.power-profiles-daemon.enable = true;

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
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Kernel parameters passed in GRUB in order to
  # allow the laptop starts normally due to the
  # hardware of this machine
   boot.kernelParams = [
   ];

  # Docker
  virtualisation.docker.package = pkgs.docker;

  # Limits for NPU (FastFlowLM requires unlimited memlock)
  security.pam.loginLimits = [
    { domain = "*"; item = "memlock"; type = "-"; value = "unlimited"; }
  ];

  systemd.settings.Manager.DefaultLimitMEMLOCK = "infinity";

  # Bluetooth support and management
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
  services.blueman.enable = true;

  # Ensure redistributable firmware is enabled for the NPU
  hardware.enableRedistributableFirmware = true;

  # List of packages installed in system profile only for this host
  environment.systemPackages = with pkgs; [
    bluez-tools
    jetbrains.pycharm-oss
    #pkgs-stable.jetbrains.pycharm-oss
    #python312Packages.pyqt5
    #python312Packages.pyyaml
    #python312Packages.sip
    #python312Packages.tkinter
    eclipses.eclipse-jee
    #jdk8
    #jdk17
    #teams-for-linux
    opencode
    #pkgs-stable.jdk8
    kdePackages.kdenlive
    chatbox
  ];

  # # Creating a symlink for openjdk8 in order to configure Eclipse properly
  # system.activationScripts.openjdk8-symlink = ''
  #   mkdir -p /var/lib/jvm
  #   chmod 777 -R /var/lib/jvm
  #   ln -sf ${pkgs-stable.jdk8}/lib/openjdk /var/lib/jvm/openjdk8
  # '';

  # Special container which will be integrated directly into the system and systemd management
  virtualisation = {
    oci-containers = {
      backend = "docker";
      containers = {
        # OpenWebUI
        open-webui = {
          image = "ghcr.io/open-webui/open-webui:main";
          autoStart = false;
          # Important. This OPENAI_API_BASE_URL will only work if
          # FastFlowLM which runs via Distrobox starts listening
          # on all the network interfaces (0.0.0.0) instead of
          # only on 127.0.0.1. In order to achieve this, it is necessary
          # to run flm with this command:
          # flm serve gemma4-it:e4b --ctx-len 32768 --pmode performance --host 0.0.0.0
          environment = {
            OPENAI_API_BASE_URL = "http://host.docker.internal:52625/v1";
            OPENAI_API_KEY = "local";
            WEBUI_AUTH = "false";
          };
          extraOptions = [
            "--add-host=host.docker.internal:host-gateway"
          ];
          ports = [
            "3000:8080"
          ];
          volumes = [
            "/home/egarcia/Docker/open-webui/data:/app/backend/data:rw"
          ];
        };
      };
    };
  };
}
