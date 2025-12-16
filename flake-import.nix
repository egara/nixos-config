{
  description = "My NixOS Flake Configuration using remote sicos module";

  inputs = {
    # 1. NixOS Unstable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # 2. Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # 3. Tu módulo sicos desde GitHub
    sicos-config = {
      url = "github:egara/nixos-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, sicos-config, ... }@inputs: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # Ajusta si usas ARM (aarch64-linux)
        
        # Pasa los inputs a los módulos para que puedan usarlos
        specialArgs = { inherit inputs; };

        modules = [

          # Import your existing hardware scan and main config
          ./hardware-configuration.nix
          ./configuration.nix

          # Import sicos module and activate options
          sicos-config.nixosModules.sicos-hyprland
          {
            programs.sicos.hyprland = {
              enable = true;
              theming.enable = true;
              powerManagement.enable = true;
              insync.enable = true;
            };
          }

          # Import home manager module and configure
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            
            home-manager.users.egarcia = { pkgs, ... }: {
              # Import sicos home manager module
              imports = [ sicos-config.homeManagerModules.sicos-hyprland ];
              home.stateVersion = "23.11";
            };
          }
        ];
      };
    };
  };
}