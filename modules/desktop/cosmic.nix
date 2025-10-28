{ pkgs, lib, ... }:

{
  ########################################
  # Cosmic                               #
  ########################################

  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;
  #systemd.packages = [ pkgs.observatory ];
  #systemd.services.monitord.wantedBy = [ "multi-user.target" ];

}
