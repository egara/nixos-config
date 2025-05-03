# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, pkgs-stable, inputs, username, ... }:
#{ config, pkgs, inputs, username, stylix, ... }:

{
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking = {
  	networkmanager = {
  		enable = true;
  	};

	extraHosts =
	''
	# StandarStripesUleApplication
	127.0.0.1	uleapp	uleapp
	127.0.0.1   uleapp-ldap-test	uleapp-ldap-test
	'';

  };

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

  # Configure console keymap
  console.keyMap = "es";

  # Deleting /tmp directory every time the system boots
  boot.tmp.cleanOnBoot = true;

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

  # Enable OpenGL
  # 20240623 - It seems hardware.opengl has been deprecated in unstable
  #hardware = {
	#  opengl = {
	#    enable = true;
	#    driSupport = true;
	#    driSupport32Bit = true;
	#  };
  #};
  # This is the new way to do it
  # More info:
  # https://github.com/NixOS/nixos-hardware/pull/997/commits/a3a9747e2846f92dad5b45b674af017f61f1408e
  # https://github.com/NixOS/nixos-hardware/issues/996
  # As it is said in the documentation, this options are not needed to be set to true because the graphics modules
  # (amdgpu for example) should enabled them by default, but just in case...
  # https://search.nixos.org/options?channel=unstable&show=hardware.graphics.enable&from=0&size=50&sort=relevance&type=packages&query=hardware.graphics
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  # Administrator account. Don't forget to set a password with ‘passwd’.
  users.users.${username} = {
    password = "administrador";
    isNormalUser = true;
    description = "Eloy";
    extraGroups = [ "wheel" "video" "audio" "networkmanager" "docker" "input" "libvirtd" "bluetooth"];
    packages = with pkgs; [
      #firefox
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Allow certain packages marked as insecure
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w" # Needed for sublime4
  ];  

  # List of unstable packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
      nvd    # NixOS package version diff tool
      firefox
      google-chrome
      kdePackages.okular
      #qmmp
      pkgs-stable.qmmp
      audacity
      pkgs-stable.carla
      nano
      #tailscale
      libreoffice
      ntfs3g
      fltk
      portaudio
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
      kdePackages.partitionmanager
      distrobox
      #fastfetch
      sublime4
      vlc
      telegram-desktop
      pkgs-stable.insync
      filezilla
      pciutils
      spotify
      bind
      encfs
      #pkgs-stable.quickemu
      #pkgs-stable.quickgui
      quickemu
      quickgui
      yt-dlp
      openconnect # For VPN extranet
      kubectl
      kubie
      kubecolor
      minikube
      usbutils
      transmission_4-gtk
      inputs.wallpaperdownloader.packages.x86_64-linux.default
      zellij
      nmap
      element-desktop
      tcpdump
      wireshark
      killall
  ];

  # List of programs that must be enabled
  programs = {
    # Partition manager
    partition-manager = {
      enable = true;
    };

    # Virtual Manager
    virt-manager = {
      enable = true;
    };
  };

  # Enabling SSH
  services = {
    # OpenSSH daemon
    openssh = {
      enable = true;
    };
  };

  # Enabling Flatpak
  services.flatpak.enable = true;

  # Virtualisation
  virtualisation = {

    # KVM-QUEMU and Virtual Manager
    libvirtd = {
      enable = true;
    };

    # Allow SPICE USB redirection for USB passthrough in QEMU
    spiceUSBRedirection = {
      enable = true;
    };

    # Docker
    docker = {
      enable = true;
      storageDriver = "overlay2";
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

  # Enabling experimental Nix flakes and disabling 'Git tree ... is dirty' message
  nix = {
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
      warn-dirty = false
    '';
  };

  # Copying display manager avatars for every user
  system.activationScripts.script.text = ''
    mkdir -p /var/lib/AccountsService/icons/
    cp /home/egarcia/Zero/nixos-config/modules/display-manager/avatars/egarcia.png /var/lib/AccountsService/icons/egarcia
  '';

########################################
# Testing Stylix
########################################
#  # Global styling with Stylix
#  stylix = {
#  	# Dark theme
#  	polarity = "dark";
#
#  	# Color scheme
#	base16Scheme = "${pkgs.base16-schemes}/share/themes/material-darker.yaml";
#
#	# Is this mandatory?
#	image = ../modules/display-manager/avatars/egarcia.png;
#
#	# Cursors
#	cursor = {
#	    package = pkgs.bibata-cursors;
#	    name = "Bibata-Modern-Classic";
#	    size = 10;
#	};
#
#	# Targets
#	targets = {
#		grub = {
#			enable = false;
#		};
#
#		gtk = {
#			enable = true;
#		};
#	};
#
#	# Fonts
# 	fonts = {
#    	monospace = {
#      		package = pkgs.nerdfonts;
#      		name = "GoMonoNerdFontPropo-Bold";
#    	};
#
#    	serif = config.stylix.fonts.monospace;
#    	sansSerif = config.stylix.fonts.monospace;
#
#
#        emoji = {
#      		package = pkgs.noto-fonts-emoji;
#      		name = "Noto Color Emoji";
#    	};
#
#    	sizes = {
#    		applications = 10;
#    		desktop = 10;
#    	};
#  	};
#
#  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}
