# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, username, ... }:

{
  # Bootloader.
  boot.loader = {
    timeout = 3;

    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };

    grub = {
      enable = true;
      devices = ["nodev"];
      efiSupport = true;
      configurationLimit = 3;
      theme = pkgs.nixos-grub2-theme;
    };
  };

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Madrid";

  # I18n.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
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
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # In order to use JACK applications
    jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Administrator account. Don't forget to set a password with ‘passwd’.
  users.users.${username} = {
    password = "administrador";
    isNormalUser = true;
    description = "Eloy";
    extraGroups = [ "wheel" "video" "audio" "networkmanager" "docker" ];
    packages = with pkgs; [
      #firefox
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
      nvd    # NixOS package version diff tool
      firefox
      google-chrome
      #audacious
      #audacity
      #carla
      #darkice
      nano
      #tailscale
      okular
      #libreoffice
      #kate
      ntfs3g
      fltk
      portaudio
      #libmp3lame
      lame
      libvorbis
      libogg
      flac
      wireplumber
      pavucontrol
      python3
      python311Packages.pip
      p7zip
      unzip
      unrar
      zip
      partition-manager
      distrobox
      neofetch
  ];

  # List of programs that must be enabled
  programs = {
    # Partition manager
    partition-manager = {
      enable = true;
    };
  };

  # List of services that must be enabled
  services = {
    # OpenSSH daemon
    openssh = {
      enable = true;
    };
  };

  # Docker
  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "btrfs";
    };
    #oci-containers = {
    #  backend = "docker";
    #  containers = {
    #    # Darkice docker container
    #    darkice = {
    #      image = "jwater7/darkice";
    #      autoStart = true;
    #      extraOptions = ["--privileged"];
    #      volumes = ["/home/administrador/config/docker/darkice/darkice.cfg:/etc/darkice.cfg:ro"];
    #    };
    #  };
    #};
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Enabling experimental Nix flakes
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = "experimental-features = nix-command flakes";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}
