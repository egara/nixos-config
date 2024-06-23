{
  description = "Flake to install several systems with all their configurations";

  # Channels (kind of repos and dependencies)
  inputs = {
    # Unstable Nix packages (bleeding edge)
    nixpkgs = {
      #url = "github:nixos/nixpkgs/nixos-unstable";
      url = # revert to (2024-06-18 until fixed driSupport)
      "github:NixOS/nixpkgs/c00d587b1a1afbf200b1d8f0b0e4ba9deb1c7f0e";
    };
    
    # Disko packages (for automatic partitioning)
    disko = {
      url = "github:nix-community/disko";
      # Follows means that if disko flake depends on nixpkgs as well, the version used there
      # must be the same that the one defined by myself, which in this case is nixos-unstable
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home manager packages (for home configurations)
    home-manager = {
      url = "github:nix-community/home-manager";
      # Follows means that if disko flake depends on nixpkgs as well, the version used there
      # must be the same that the one defined by myself, which in this case is nixos-unstable
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprswitch (for windows switching in Hyprland)
    hyprswitch = {
      url = "github:h3rmt/hyprswitch/release";
    };

#    # Stylix (for styling)
#    stylix = {
#      url = "github:danth/stylix";
#    };

  };

  # Function that tells my flake which to use and what do what to do with the dependencies.
#  outputs = inputs @ { self, disko, nixpkgs, home-manager, hyprswitch, stylix, ... }:
  outputs = inputs @ { self, disko, nixpkgs, home-manager, hyprswitch, ... }:
    # Variables
    let
      username = "egarcia";
      location = "$HOME/.setup";
    in {
      nixosConfigurations = (
        # Imports ./hosts/default.nix module
        import ./hosts {
          inherit (nixpkgs) lib;
           # Also inherit disko, home-manager and the rest of the variables so it does not need 
           # to be defined anymore.
#          inherit inputs nixpkgs disko home-manager hyprswitch stylix username location;
          inherit inputs nixpkgs disko home-manager hyprswitch username location;
        }
      );
    };
}
