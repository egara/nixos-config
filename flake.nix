{
  description = "A very basic flake";

  # Channels (kind of repos)
  inputs = {
    # Unstable packages (bleeding edge)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    # Home manager packages
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Function that tells my flake which to use and what do what to do with the dependencies.
  outputs = inputs @ { self, nixpkgs, home-manager, ... }:   
    # Variables
    let
      user = "egarcia";
      location = "$HOME/.setup";
    in {
      nixosConfigurations = (
        # Imports ./hosts/default.nix
        import ./hosts {
          inherit (nixpkgs) lib;
           # Also inherit home-manager so it does not need to be defined here.
          inherit inputs nixpkgs home-manager user location;
        }
      );
    };
}
