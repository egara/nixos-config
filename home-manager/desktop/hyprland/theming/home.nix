{ config, pkgs, ... }:

{

  #############################
  # Theming with Home Manager #
  #############################
  # Cursor theming will be globally managed by stylix (see below)
  #home.pointerCursor = {
  #  gtk.enable = true;
  #  package = pkgs.bibata-cursors;
  #  name = "Bibata-Modern-Classic";
  #  size = 10;
  #};

  # GTK configuration and theming
  gtk = {
    enable = true;

    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };

    # Icon theming will be globally managed by Stylix (see below)
    #iconTheme = {
    #  package = pkgs.papirus-icon-theme;
    #  name = "Papirus-Dark";
    #};

    font = {
      package = pkgs.nerd-fonts.go-mono;
      name = "GoMonoNerdFontPropo-Bold";
      size = 10;
    };

    gtk3 = {
      extraConfig.gtk-application-prefer-dark-theme = true;
    };    

    gtk4 = {
      extraConfig.gtk-application-prefer-dark-theme = true;
    };    
  };

  # QT configuration and theming
  qt = {
    enable = true;
    platformTheme = {
      name = "gtk";
    };
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };

  ########################################
  # Theming with Stylix
  ########################################
   # Global styling with Stylix
   stylix = {
    enable = true;

    # Dark theme
    polarity = "dark";

    # Color scheme
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

    # Is this mandatory?
    image = ../../../modules/display-manager/avatars/egarcia.png;

    # Cursors
    cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Classic";
        size = 10;
    };

    # Icons
    icons = {
      enable = true;
      package = pkgs.papirus-icon-theme;
      dark = "Papirus-Dark";
      light = "Papirus-Dark";
    };

    # Fonts
    fonts = {
      monospace = {
          package = pkgs.nerd-fonts.go-mono;
          name = "GoMonoNerdFontPropo-Bold";
      };

      serif = config.stylix.fonts.monospace;
      sansSerif = config.stylix.fonts.monospace;

      emoji = {
          package = pkgs.noto-fonts-emoji;
          name = "Noto Color Emoji";
      };

      sizes = {
        applications = 10;
        desktop = 10;
        popups = 10;
        terminal = 10;
      };
    };

    # Targets
    targets = {

      kitty = {
        enable = true;
      };

      # GTK and QT theming will be managed by Home Manger (see above)
      gtk = {
        enable = false;     
      };

      qt = {
        enable = false;
      };

    };

   };
}
