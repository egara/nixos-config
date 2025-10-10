{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.autofirma-nix.nixosModules.default
  ];

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
      # "DNIeRemote" = "${config.programs.dnieremote.finalPackage}/lib/libdnieremotepkcs11.so";
    };
  };
  # Enable PC/SC smart card service
  services.pcscd.enable = true;
}
