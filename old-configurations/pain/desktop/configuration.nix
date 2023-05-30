# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration-intel.nix
    ];

  # Bootloader.
  boot.loader = {
    timeout = 3;
    grub = {
      enable = true;
      version = 2;
      device = "/dev/sda";
      configurationLimit = 3;
      theme = pkgs.nixos-grub2-theme;
    };
  };

  networking.hostName = "pain"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Madrid";

  # Select internationalisation properties.
  i18n.defaultLocale = "es_ES.utf8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_ES.utf8";
    LC_IDENTIFICATION = "es_ES.utf8";
    LC_MEASUREMENT = "es_ES.utf8";
    LC_MONETARY = "es_ES.utf8";
    LC_NAME = "es_ES.utf8";
    LC_NUMERIC = "es_ES.utf8";
    LC_PAPER = "es_ES.utf8";
    LC_TELEPHONE = "es_ES.utf8";
    LC_TIME = "es_ES.utf8";
  };

  # Desktop Environment
  services = {
    xserver = {
      enable = true;
      layout = "es";
      xkbVariant = "";
      displayManager = {
        sddm.enable = true;
      };
      desktopManager.plasma5.enable = true;
    };
  };

  # Configure console keymap
  console.keyMap = "es";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  #sound.enable = true;
  #hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Administrator account. Don't forget to set a password with ‘passwd’.
  users.users.administrador = {
    password = "administrador";
    isNormalUser = true;
    description = "Administrador";
    extraGroups = [ "wheel" "video" "audio" "networkmanager" "docker" ];
    packages = with pkgs; [
      #firefox
    ];
  };

  # Radio user
  users.users.radio = {
    password = "radio";
    isNormalUser = true;
    description = "Radio";
    extraGroups = [ "video" "audio" "networkmanager" ];
    packages = with pkgs; [
      #firefox
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
      firefox
      google-chrome
      audacious
      audacity
      carla
      #darkice
      nano
      git
      curl
      wget
      tailscale
      okular
      libreoffice
      kate
      ntfs3g
      gcc
      gnumake
      fltk
      portaudio
      #libmp3lame
      lame
      libvorbis
      libogg
      flac
      wireplumber
      pavucontrol
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # OpenSSH daemon.
  services.openssh.enable = true;

  # Tailscale
  services.tailscale.enable = true;

  # create a oneshot job to authenticate to Tailscale
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    # make sure tailscale is running before trying to connect to tailscale
    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];

    # set this service as a oneshot job
    serviceConfig.Type = "oneshot";

    # have the job run this shell script
    script = with pkgs; ''
      # wait for tailscaled to settle
      sleep 2

      # check if we are already authenticated to tailscale
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi

      # otherwise authenticate with tailscale
      ${tailscale}/bin/tailscale up -authkey CHANGETHIS-ADD-TAILSCALE-KEY
    '';
  };

  # Docker
  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "btrfs";
    };
    oci-containers = {
      backend = "docker";
      containers = {
        # Darkice docker container
        darkice = {
          image = "jwater7/darkice";
          autoStart = true;
          extraOptions = ["--privileged"];
          volumes = ["/home/administrador/config/docker/darkice/darkice.cfg:/etc/darkice.cfg:ro"];
        };
      };
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}
