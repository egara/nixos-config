# { lib, inputs, nixpkgs, nixpkgs-stable, disko, home-manager, hyprswitch, wallpaperdownloader, hyprland, hyprland-plugins, username, location, ... }:
# { lib, inputs, nixpkgs, nixpkgs-stable, disko, home-manager, hyprswitch, wallpaperdownloader, username, location, autofirma-nix, ... }:
# { lib, inputs, nixpkgs, nixpkgs-stable, disko, home-manager, wallpaperdownloader, username, location, autofirma-nix, walker, ... }: 
{ lib, inputs, nixpkgs, nixpkgs-stable, disko, home-manager, wallpaperdownloader, username, location, autofirma-nix, ... }: 
let
  # System architecture
  system = "x86_64-linux";
 
  # Unstable packages
  pkgs = import nixpkgs {
    inherit system;

    # Allow proprietary software
    config.allowUnfree = true;
  };

  # Stable packages
  pkgs-stable = import nixpkgs-stable {
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
      inherit inputs username location pkgs-stable;
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
  rocket =
    let
      hostArg = {
        hostName = "rocket";
        desktop = "plasma"; # "hyprland" or "plasma"
      };
    in
    lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit inputs username location pkgs-stable;
        host = hostArg;
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

        # Execute common configuration module for rocket
        ./rocket/configuration.nix

        # Common desktop configuration for the host
        ./rocket/desktop.nix

        # Desktop Environment modules
        ({ config, lib, host, ... }: {
          imports =
            lib.optionals (host.desktop == "hyprland") [
              ../modules/desktop/hyprland.nix
            ] ++ lib.optionals (host.desktop == "plasma") [
              ../modules/desktop/plasma.nix
            ];
        })

        #      # Stylix configuration module
        #      stylix.nixosModules.stylix

        # Execute home manager module
        home-manager.nixosModules.home-manager {
          home-manager.backupFileExtension = "backup";
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {
            # inherit username hyprland-plugins;
            inherit username;
            host = hostArg;
          };
          home-manager.users.${username} = {
            imports = [ (import ./home.nix) ] ++ lib.optionals (hostArg.desktop == "hyprland") [
              (import ../home-manager/desktop/hyprland/home.nix)
            ];
          };
        }
      ];
    };

  # Ironman profile
  ironman =
    let
      hostArg = {
        hostName = "ironman";
        desktop = "hyprland"; # "hyprland" or "plasma"
      };
    in
    lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit inputs username location pkgs-stable;
        host = hostArg;
      };

      modules = [
        # Execute disko module
        disko.nixosModules.disko {
          # module configuration
          _module.args.disks = [ "/dev/sda" ];
          imports = [(import ./ironman/disko-config.nix)];
        }

        # Execute hardware configuration module
        ./ironman/hardware-configuration.nix

        # Execute common configuration for EFI boot systems
        ./efi-configuration.nix

        # Execute common configuration module
        ./configuration.nix

        # Execute common configuration module for ironman
        ./ironman/configuration.nix

        # Common desktop configuration for the host
        ./ironman/desktop.nix

        # Autofirma module (it is a module itself!)
        autofirma-nix.nixosModules.default

        ({ config, pkgs, ... }: {
          # The autofirma command becomes available system-wide
          programs.autofirma = {
            enable = true;
            firefoxIntegration.enable = true;
          };

          # # DNIeRemote integration for using phone as NFC reader
          # programs.dnieremote = {
          #   enable = true;
          # };

          # The FNMT certificate configurator
          programs.configuradorfnmt = {
            enable = true;
            firefoxIntegration.enable = true;
          };

          # Firefox configured to work with AutoFirma
          programs.firefox = {
            enable = true;
            policies.SecurityDevices = {
              "OpenSC PKCS#11" = "${pkgs.opensc}/lib/opensc-pkcs11.so";
              "DNIeRemote" = "${config.programs.dnieremote.finalPackage}/lib/libdnieremotepkcs11.so";
            };
          };

          # Enable PC/SC smart card service
          services.pcscd.enable = true;
        })

        # Desktop Environment module (this is a module itself!)
        ({ config, lib, host, ... }: {
          # Depending on the desktop, some modules are imported
          imports =
            lib.optionals (host.desktop == "hyprland") [
              ../modules/desktop/hyprland.nix
            ] ++ lib.optionals (host.desktop == "plasma") [
              ../modules/desktop/plasma.nix
            ];
        })

        # Execute home manager module
        home-manager.nixosModules.home-manager {
          # Module configuration
          home-manager.backupFileExtension = "backup";
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {
            # inherit username hyprland-plugins;
            inherit username;
            host = hostArg;
          };
          home-manager.users.${username} = {
            imports = [ (import ./home.nix) ] ++ lib.optionals (hostArg.desktop == "hyprland") [
              (import ../home-manager/desktop/hyprland/home.nix)
            ];
          };
        }
      ];
    };

  # Next profile if it is necessary
}
