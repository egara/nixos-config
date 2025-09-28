{ lib, inputs, nixpkgs, nixpkgs-stable, disko, home-manager, wallpaperdownloader, username, autofirma-nix, stylix, ... }:
let
  # System architecture
  system = "x86_64-linux";

  # Unstable packages
  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };

  # Stable packages
  pkgs-stable = import nixpkgs-stable {
    inherit system;
    config.allowUnfree = true;
  };

  lib = nixpkgs.lib;

  # Function to generate a host configuration
  mkHost = { hostName, desktop, extraModules ? [], homeManagerExtraImports ? [] }:

    let
      hostArg = { inherit hostName desktop; };
    in
    lib.nixosSystem {

      inherit system;

      specialArgs = {
        inherit inputs username pkgs-stable;
        host = hostArg;
      };

      modules = extraModules ++ [
        # Stylix module
        #stylix.nixosModules.stylix

        # Common configuration for all hosts
        ./configuration.nix

        # Desktop Environment modules
        # It is a module itself!
        ({ config, lib, host, ... }: {
          imports =
            lib.optionals (host.desktop == "hyprland") [ ../modules/desktop/hyprland.nix ] ++
            lib.optionals (host.desktop == "plasma") [ ../modules/desktop/plasma.nix ];
        })

        # Home Manager module and configurations
        home-manager.nixosModules.home-manager {
          # Module configuration
          home-manager.backupFileExtension = "backup";
          home-manager.useGlobalPkgs = false;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {
            inherit username pkgs;
            host = hostArg;
          };
          home-manager.users.${username} = {
            imports = [ 
              stylix.homeModules.stylix
              (import ./home.nix)
            ]
              ++ lib.optionals (desktop == "hyprland") [ 
                (import ../home-manager/desktop/hyprland/home.nix)
                (import ../home-manager/desktop/hyrpland/theming/home.nix)
              ]
              ++ homeManagerExtraImports;
          };
        }
      ];
    };

  # Modules for VM
  vmModules = [
    disko.nixosModules.disko {
      _module.args.disks = [ "/dev/vda" ];
      imports = [(import ./vm/disko-config.nix)];
    }
    ./vm/hardware-configuration.nix
    ./efi-configuration.nix
    ./vm/configuration.nix
  ];
  vmHomeManagerExtraImports = [ (import ./vm/home.nix) ];

  # Modules for Rocket
  rocketModules = [
    disko.nixosModules.disko {
      _module.args.disks = [ "/dev/sda" ];
      imports = [(import ./rocket/disko-config.nix)];
    }
    ./rocket/hardware-configuration.nix
    ./bios-configuration.nix
    ./rocket/configuration.nix
  ];

  # Modules for Ironman
  ironmanModules = [
    disko.nixosModules.disko {
      _module.args.disks = [ "/dev/sda" ];
      imports = [(import ./ironman/disko-config.nix)];
    }
    ./ironman/hardware-configuration.nix
    ./efi-configuration.nix
    ./ironman/configuration.nix
    autofirma-nix.nixosModules.default
    # It is a module itself!
    ({ config, pkgs, ... }: {
      # The autofirma command becomes available system-wide
      programs.autofirma = {
        enable = true;
        firefoxIntegration.enable = true;
      };
      # # DNIeRemote integration for using phone as NFC reader
      # programs.dnieremote = {
      #   enable = true;
      # };
      # The FNMT certificate configurator
      programs.configuradorfnmt = {
        enable = true;
        firefoxIntegration.enable = true;
      };
      # Firefox configured to work with AutoFirma
      programs.firefox = {
        enable = true;
        policies.SecurityDevices = {
          "OpenSC PKCS#11" = "${pkgs.opensc}/lib/opensc-pkcs11.so";
          "DNIeRemote" = "${config.programs.dnieremote.finalPackage}/lib/libdnieremotepkcs11.so";
        };
      };
      # Enable PC/SC smart card service
      services.pcscd.enable = true;
    })
  ];

  # Modules for Taskmaster
  taskmasterModules = [
    disko.nixosModules.disko {
      _module.args.disks = [ "/dev/nvme0n1" ];
      imports = [(import ./taskmaster/disko-config.nix)];
    }
    ./taskmaster/hardware-configuration.nix
    ./efi-configuration.nix
    ./taskmaster/configuration.nix
    autofirma-nix.nixosModules.default
    # It is a module itself!
    ({ config, pkgs, ... }: {
      # The autofirma command becomes available system-wide
      programs.autofirma = {
        enable = true;
        firefoxIntegration.enable = true;
      };
      # # DNIeRemote integration for using phone as NFC reader
      # programs.dnieremote = {
      #   enable = true;
      # };
      # The FNMT certificate configurator
      programs.configuradorfnmt = {
        enable = true;
        firefoxIntegration.enable = true;
      };
      # Firefox configured to work with AutoFirma
      programs.firefox = {
        enable = true;
        policies.SecurityDevices = {
          "OpenSC PKCS#11" = "${pkgs.opensc}/lib/opensc-pkcs11.so";
          "DNIeRemote" = "${config.programs.dnieremote.finalPackage}/lib/libdnieremotepkcs11.so";
        };
      };
      # Enable PC/SC smart card service
      services.pcscd.enable = true;
    })
  ];

in
{
  # VM profile
  vm = mkHost {
    hostName = "experimental";
    desktop = "plasma";
    extraModules = vmModules;
    homeManagerExtraImports = vmHomeManagerExtraImports;
  };

  # Rocket profiles
  "rocket-plasma" = mkHost {
    hostName = "rocket";
    desktop = "plasma";
    extraModules = rocketModules;
  };
  "rocket-hyprland" = mkHost {
    hostName = "rocket";
    desktop = "hyprland";
    extraModules = rocketModules;
  };

  # Ironman profiles
  "ironman-plasma" = mkHost {
    hostName = "ironman";
    desktop = "plasma";
    extraModules = ironmanModules;
  };
  "ironman-hyprland" = mkHost {
    hostName = "ironman";
    desktop = "hyprland";
    extraModules = ironmanModules;
  };

  # Taskmaster profiles
  "taskmaster-plasma" = mkHost {
    hostName = "taskmaster";
    desktop = "plasma";
    extraModules = taskmasterModules;
  };
  "taskmaster-hyprland" = mkHost {
    hostName = "taskmaster";
    desktop = "hyprland";
    extraModules = taskmasterModules;
  };
}
