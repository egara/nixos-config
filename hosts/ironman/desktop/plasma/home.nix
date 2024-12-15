#
#  Home-manager configuration for desktop

{ pkgs, config, ... }:

{
  imports = [
    # Wofi configuration via home-manager
    #../../../../home-manager/wofi

  ];

  home = {
    # QMMP
    # If QMMP doesn't switch to Winamp skin automatically, go to Edit -> Settings -> Plugins and check
    # Skinned User Interface within User Interfaces section. Then, restart QMMP
        file.".config/qmmp/skins/winamp_classic.wsz".source = ../../../../home-manager/qmmp/skins/winamp_classic.wsz;    

  };

  # Virtual Manager special configuration (https://nixos.wiki/wiki/Virt-manager)
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

  programs.home-manager.enable = true;
  
  # Cursor theming
  home.pointerCursor = {
    gtk.enable = true;
    # x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 10;
  };

  # GTK configuration and theming
  gtk = {
    enable = true;

    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };

    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };

    font = {
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

  # Kitty terminal emulator special configuration
  programs.kitty = {
    enable = true;
    font = {
      package = pkgs.nerdfonts;
      name = "GoMonoNerdFontPropo-Bold";
      size = 10;
    };
    theme = "Catppuccin-Mocha";
    shellIntegration = {
      enableBashIntegration = true;
    };
  };
}