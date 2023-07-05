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
      # Test if hostname can be defined as a variable and pass it to configuration module
      # Execute disko module
      disko.nixosModules.disko {
        _module.args.disks = [ "/dev/vda" ];
        imports = [(import ./vm/disko-config.nix)];
      }

      # Execute hardware configuration module
      ./vm/hardware-configuration.nix
      
      # Execute configuration module
      ./configuration.nix
 
      # Execute home manager module
      home-manager.nixosModules.home-manager {
        home-manager.useGlobalPkgs = true;
        home-manager.useUsernamePackages = true;
        home-manager.extraSpecialArgs = {
          inherit username;
          host = {
            hostName = "experimental";
          };
        };
        home-manager.usernames.${username} = {
          #imports = [(import ./home.nix)] ++ [(import ./vm/home.nix)];
          imports = [(import ./home.nix)];
        };
      }
    ];
  };

  # Next profile if it is necessary
}