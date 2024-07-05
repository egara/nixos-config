#{ lib, inputs, nixpkgs, disko, home-manager, hyprswitch, stylix, username, location, ... }:
{ lib, inputs, nixpkgs, disko, home-manager, hyprswitch, username, location, ... }:
 
let
  # System architecture
  system = "x86_64-linux";
 
  pkgs = import nixpkgs {
    inherit system;

    # Allow proprietary software
    config.allowUnfree = true;
  };
 
  lib = nixpkgs.lib;
in
{
  ############ Profiles ############

  # VM profile
  vm = lib.nixosSystem {

    inherit system;
    
    specialArgs = {
      inherit inputs username location;
      host = {
        hostName = "experimental";
      };
    };

    modules = [
      # Execute disko module
      disko.nixosModules.disko {
        _module.args.disks = [ "/dev/vda" ];
        imports = [(import ./vm/disko-config.nix)];
      }

      # Execute hardware configuration module
      ./vm/hardware-configuration.nix

      # Execute common configuration for EFI boot systems
      ./efi-configuration.nix
      
      # Execute common configuration module
      ./configuration.nix

      # Execute specific configuration module for this profile
      ./vm/configuration.nix
 
      # Execute home manager module
      home-manager.nixosModules.home-manager {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {
          inherit username;
          host = {
            hostName = "experimental";
          };
        };
        home-manager.users.${username} = {
          imports = [(import ./home.nix)] ++ [(import ./vm/home.nix)];
        };
      }
    ];

  };

  # Rocket profile (for testing purposes)
  # Hyprland configurations by default
  # Comment Hyprland lines and uncomment Plasma 6 lines in order to switch installations
  rocket = lib.nixosSystem {

    inherit system;
    
    specialArgs = {
      inherit inputs username location;
      host = {
        hostName = "rocket";
      };
    };

    modules = [
      # Execute disko module
      disko.nixosModules.disko {
        _module.args.disks = [ "/dev/sda" ];
        imports = [(import ./rocket/disko-config.nix)];
      }

      # Execute hardware configuration module
      ./rocket/hardware-configuration.nix

      # Execute common configuration for BIOS legacy systems
      ./bios-configuration.nix
      
      # Execute common configuration module
      ./configuration.nix

      ########################
      # Hyprland Configuration
      ########################
      # Execute specific configuration module for this profile (default)
      ./rocket/desktop/hyprland/configuration.nix
 
      ########################
      # Plasma 6 Configuration
      ########################
      # Execute specific configuration module for this profile
      #./rocket/rocket-plasma-configuration.nix

#      # Stylix configuration module
#      stylix.nixosModules.stylix

      # Execute home manager module
      home-manager.nixosModules.home-manager {
        home-manager.backupFileExtension = "backup";
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {
          inherit username;
          host = {
            hostName = "rocket";
          };
        };
        home-manager.users.${username} = {
          ########################
          # Hyprland Configuration
          ########################
          # (default)
          imports = [(import ./home.nix)] ++ [(import ./rocket/desktop/hyprland/home.nix)];

          ########################
          # Plasma 6 Configuration
          ########################
          #imports = [(import ./home.nix)] ++ [(import ./rocket/rocket-plasma-home.nix)];
        };
      }

    ];

  };

  # Ironman profile
  # Hyprland configurations by default
  # Comment Hyprland lines and uncomment Plasma 6 lines in order to switch installations
  ironman = lib.nixosSystem {

    inherit system;
    
    specialArgs = {
      inherit inputs username location;
      host = {
        hostName = "ironman";
      };
    };

    modules = [
      # Execute disko module
      disko.nixosModules.disko {
        _module.args.disks = [ "/dev/sda" ];
        imports = [(import ./ironman/disko-config.nix)];
      }

      # Execute hardware configuration module
      ./ironman/hardware-configuration.nix

      # Execute common configuration for EFI boot systems
      ./efi-configuration.nix
      
      # Execute common configuration module
      ./configuration.nix

      ########################
      # Hyprland Configuration
      ########################
      # Execute specific configuration module for this profile (default)
      ./ironman/desktop/hyprland/configuration.nix
 
      # Execute home manager module
      home-manager.nixosModules.home-manager {
        home-manager.backupFileExtension = "backup";
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {
          inherit username;
          host = {
            hostName = "ironman";
          };
        };
        home-manager.users.${username} = {
          ########################
          # Hyprland Configuration
          ########################
          # (default)
          imports = [(import ./home.nix)] ++ [(import ./ironman/desktop/hyprland/home.nix)];
        };
      }

    ];

  };

  # Next profile if it is necessary
}