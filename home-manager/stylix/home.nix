{ config, pkgs, ... }:

{
  ########################################
  # Testing Stylix
  ########################################
   # Global styling with Stylix
   stylix = {
    enable = true;

    # Dark theme
    polarity = "dark";

    # Color scheme
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

    # Is this mandatory?
    image = ../../modules/display-manager/avatars/egarcia.png;

    # Cursors
    cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Classic";
        size = 10;
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

      # GTK and QT styling settings will be done manually
      gtk = {
        enable = false;     
      };

      qt = {
        enable = false;
      };

    };

   };
}
