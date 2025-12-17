{ lib, inputs, nixpkgs, nixpkgs-stable, disko, home-manager, wallpaperdownloader, autofirma-nix, stylix, walker, nixos-hardware, self, ... }:
#Variables
let
  # Main user
  username = "egarcia";
  
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
            lib.optionals (host.desktop == "plasma") [ ../modules/desktop/plasma.nix ] ++
            lib.optionals (host.desktop == "cosmic") [ ../modules/desktop/cosmic.nix ] ++
            # Import the new sicos hyprland module
            lib.optionals (host.desktop == "hyprland") [ self.nixosModules.sicos-hyprland ];
          
          # Enable the sicos module if desktop is hyprland
          config = lib.mkIf (host.desktop == "hyprland") {
            programs.sicos.hyprland.enable = true;
            programs.sicos.hyprland.theming.enable = true;
            programs.sicos.hyprland.powerManagement.enable = true;
            programs.sicos.hyprland.insync.enable = true;
            programs.sicos.hyprland.insync.package = pkgs-stable.insync;
            programs.sicos.hyprland.kanshi.enable = true;

            # Custom config files

            # Hyprland
            programs.sicos.hyprland.hyprland.configFile = builtins.path { path = ../home-manager/desktop/hyprland/config/hyprland.conf; };

            # Kanshi
            programs.sicos.hyprland.kanshi.configFile = builtins.path { path = ../home-manager/desktop/hyprland/programs/kanshi/config; };

            # Waybar
            programs.sicos.hyprland.waybar.configFile = builtins.path { path = ../home-manager/desktop/hyprland/programs/waybar/config.jsonc; };
            programs.sicos.hyprland.waybar.styleFile = builtins.path { path = ../home-manager/desktop/hyprland/programs/waybar/style.css; };
          };
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
                (import ../modules/sicos/hyprland/hm-module.nix)
              ]
              ++ homeManagerExtraImports;

            # Activation script to clean up leftover backup files
            # This prevents errors on rebuild if a previous one failed
            home.activation = {
              cleanup-hm-backups = home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
                $DRY_RUN_CMD find "$HOME" -name "*.backup" -delete
              '';
            };
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
    ../modules/custom/autofirma.nix
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
    ../modules/custom/autofirma.nix
  ];

  # Modules for Strange
  strangeModules = [
    disko.nixosModules.disko {
      _module.args.disks = [ "/dev/nvme0n1" ];
      imports = [(import ./strange/disko-config.nix)];
    }
    nixos-hardware.nixosModules.framework-amd-ai-300-series
    ./strange/hardware-configuration.nix
    ./efi-configuration.nix
    ./strange/configuration.nix
    ../modules/custom/autofirma.nix
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
  "rocket-cosmic" = mkHost {
    hostName = "rocket";
    desktop = "cosmic";
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
  "strange-hyprland" = mkHost {
    hostName = "strange";
    desktop = "hyprland";
    extraModules = strangeModules;
  };
}