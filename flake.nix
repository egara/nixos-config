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
      url = "github:nixos/nixpkgs?ref=nixos-25.11";
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
     # url = "github:nix-community/autofirma-nix";  # For nixpkgs-unstable
     # inputs.nixpkgs.follows = "nixpkgs-unstable";
     # Stable release
     url = "github:nix-community/autofirma-nix/release-25.11";  # For NixOS 24.11
     inputs.nixpkgs.follows = "nixpkgs";
   };

    # autofirma-nix = {
    #   url = "git+https://github.com/nix-community/autofirma-nix.git?rev=75770f68709e764659712ff152193d7986db2530";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # Walker and Elephant
    elephant = {
      url = "github:abenz1267/elephant";
    };
    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
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

    # Stylix (for styling)
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOs Hardware project for supporting different systems
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };

  # Nix Flatpak. Install and manage flatpaks programatically using Nix
    # https://github.com/gmodena/nix-flatpak
    nix-flatpak = {
      url = "github:gmodena/nix-flatpak";
    };
  };

  # The binary cache configuration is strongly recommended to avoid unnecessary local compilation.
  # See also https://nixos.wiki/wiki/Binary_Cache
  # extra-* prefix is used to allow other users (like egarcia) to define binary caches
  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org" # It is recommended in Autofirma flake tutorial https://nix-community.github.io/autofirma-nix
      "https://walker-git.cachix.org" # It is recommended for walker application launcher
    ];

    # Public keys that verify the integrity of binaries downloaded from the substituters.
    # You need to include keys for all caches you trust.
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "walker-git.cachix.org-1:vmC0ocfPWh0S/vRAQGtChuiZBTAe4wiKDeyyXM0/7pM="
    ];
  };

  # Function that tells my flake which to use and what do what to do with the dependencies.
  # outputs = inputs @ { self, disko, nixpkgs, nixpkgs-stable, home-manager, hyprswitch, wallpaperdownloader, hyprland, hyprland-plugins, ... }:
  # outputs = inputs @ { self, disko, nixpkgs, nixpkgs-stable, home-manager, wallpaperdownloader, autofirma-nix, walker, ... }:
  outputs = inputs @ { self, disko, nixpkgs, nixpkgs-stable, home-manager, wallpaperdownloader, autofirma-nix, stylix, walker, nixos-hardware, nix-flatpak, ... }:
  {
    nixosModules = {
      sicos-hyprland = {
        _module.args.sicos-source-path = self;
        imports = [
          walker.nixosModules.default
          (import ./modules/sicos/hyprland)
        ];
      };
    };

    homeManagerModules = {
      sicos-hyprland = {
        imports = [
          stylix.homeModules.stylix
          (import ./modules/sicos/hyprland/hm-module.nix)
        ];
      };
    };

    nixosConfigurations = (
      # Imports ./hosts/default.nix module
      import ./hosts {
        inherit (nixpkgs) lib;
        # Also inherit disko, home-manager and the rest of the variables so it does not need
        # to be defined anymore.
        # inherit inputs nixpkgs nixpkgs-stable disko home-manager hyprswitch wallpaperdownloader hyprland hyprland-plugins username location;
        # inherit inputs nixpkgs nixpkgs-stable disko home-manager wallpaperdownloader username location autofirma-nix walker;
        inherit inputs nixpkgs nixpkgs-stable disko home-manager wallpaperdownloader autofirma-nix stylix walker nixos-hardware nix-flatpak self;
      }
    );
  };

}
