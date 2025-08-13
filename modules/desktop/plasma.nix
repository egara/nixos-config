{ pkgs, ... }:

{
  ##########################################
  # Plasma 6                               #
  ##########################################

  services = {
    # SDDM
    displayManager = {
      sddm = {
        enable = true;
        wayland = {
          enable = true;
        };
        theme = "breeze";
      };
    };

    # Xserver
    xserver = {
      enable = true;

      xkb = {
        layout = "es";
        variant = "";
      };
    };

    # Plasma 6
    desktopManager = {
      plasma6 = {
        enable = true;
      };
    };

    # Power profiles
    power-profiles-daemon = {
      enable = false;
    };
  };

  # Packages excluded from Plasma 6 metapackage
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    kate
  ];  

  # Extra packages useful for Plasma 6
  environment.systemPackages = with pkgs; [
    konsave
    bash-completion
  ];
}
