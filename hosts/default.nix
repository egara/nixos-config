#
#  These are the different profiles that can be used when building NixOS.
#
#  flake.nix 
#   └─ ./hosts  
#       ├─ default.nix *
#       ├─ configuration.nix
#       ├─ home.nix
#       └─ ./desktop OR ./laptop OR ./work OR ./vm
#            ├─ ./default.nix
#            └─ ./home.nix 
#
 
{ lib, inputs, nixpkgs, disko, home-manager, username, location, ... }:
 
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
        _module.args.disks = [ "/dev/vda" ];
        imports = [(import ./rocket/disko-config.nix)];
      }

      # Execute hardware configuration module
      ./rocket/hardware-configuration.nix
      
      # Execute common configuration module
      ./configuration.nix

      # Execute specific configuration module for this profile
      ./rocket/configuration.nix
 
      # Execute home manager module
      home-manager.nixosModules.home-manager {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {
          inherit username;
          host = {
            hostName = "rocket";
          };
        };
        home-manager.users.${username} = {
          imports = [(import ./home.nix)] ++ [(import ./rocket/home.nix)];
        };
      }
    ];

  };

  # Next profile if it is necessary
}
