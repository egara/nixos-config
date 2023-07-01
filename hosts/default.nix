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
 
{ lib, inputs, nixpkgs, disko, home-manager, user, location, ... }:
 
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
      inherit inputs user location;
      host = {
        hostName = "experimental";
        #mainMonitor = "Virtual-1";
      };
    };

    modules = [
      # Execute disko module
      disko.nixosModules.disko {
        _module.args.disks = [ "/dev/vda" ];
        imports = [(import ./disko-config.nix)];
      }
      
      # Execute configuration module
      ./configuration.nix
 
      # Execute home manager module
      home-manager.nixosModules.home-manager {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {
          inherit user;
          host = {
            hostName = "experimental";
            #mainMonitor = "Virtual-1";
          };
        };
        home-manager.users.${user} = {
          #imports = [(import ./home.nix)] ++ [(import ./vm/home.nix)];
          imports = [(import ./home.nix)];
        };
      }
    ];
  };

  # Next profile if it is necessary
}