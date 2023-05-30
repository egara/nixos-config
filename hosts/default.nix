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

{ lib, inputs, nixpkgs, home-manager, user, location, ... }:

let
  system = "x86_64-linux";                                  # System architecture

  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;                              # Allow proprietary software
  };

  lib = nixpkgs.lib;
in
{
  vm = lib.nixosSystem {                                    # VM profile
    inherit system;
    specialArgs = {
      inherit inputs user location;
      host = {
        hostName = "experimental";
        #mainMonitor = "Virtual-1";
      };
    };
    modules = [
      ./configuration.nix

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
}
