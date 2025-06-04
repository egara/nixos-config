{
  description = "Flake to install several systems with all their configurations";

  # Channels (kind of repos and dependencies)
  inputs = {
    # Unstable Nix packages (bleeding edge)
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    # Stable Nix packages
    nixpkgs-stable = {
      url = "github:nixos/nixpkgs?ref=nixos-25.05";
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

#    # Hyprswitch (for windows switching in Hyprland)
#    hyprswitch = {
#      url = "github:h3rmt/hyprswitch/release";
#    };

    # WallpaperDownloader flake
    wallpaperdownloader = {
      url = "github:egara/wallpaperdownloader-flake";
    };

    # Autofirma flake
    # For more information https://nix-community.github.io/autofirma-nix
    autofirma-nix = {
      url = "github:nix-community/autofirma-nix";  # For nixpkgs-unstable
      # url = "github:nix-community/autofirma-nix/release-24.11";  # For NixOS 24.11
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # # Hyprland
    # hyprland = {
    #   url = "github:hyprwm/Hyprland";
    # };

    # # Hyprland plugins
    # hyprland-plugins = {
    #   url = "github:hyprwm/hyprland-plugins";
    #   inputs.hyprland.follows = "hyprland";
    # };

#    # Stylix (for styling)
#    stylix = {
#      url = "github:danth/stylix";
#    };

  };

  # The binary cache configuration is strongly recommended to avoid unnecessary local compilation.
  # It is recommended in Autofirma flake tutorial https://nix-community.github.io/autofirma-nix
  # See also https://nixos.wiki/wiki/Binary_Cache
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # Function that tells my flake which to use and what do what to do with the dependencies.
  # outputs = inputs @ { self, disko, nixpkgs, nixpkgs-stable, home-manager, hyprswitch, wallpaperdownloader, hyprland, hyprland-plugins, ... }:
  # outputs = inputs @ { self, disko, nixpkgs, nixpkgs-stable, home-manager, hyprswitch, wallpaperdownloader, autofirma-nix, ... }:
  outputs = inputs @ { self, disko, nixpkgs, nixpkgs-stable, home-manager, wallpaperdownloader, autofirma-nix, ... }:
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
          # inherit inputs nixpkgs nixpkgs-stable disko home-manager hyprswitch wallpaperdownloader hyprland hyprland-plugins username location;
          inherit inputs nixpkgs nixpkgs-stable disko home-manager wallpaperdownloader username location autofirma-nix;
        }
      );
    };
}
