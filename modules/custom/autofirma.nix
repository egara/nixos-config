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

  # Importante!
  # Para que determinadas sedes electrónicas funcionen correctamente, sin hacer nada en los
  # navegadores e intentar indetificarse, la conexión entre el navegador y Autofirma puede
  # que falle a través de un socket que abre autofirma en 127.0.0.1. Es necesario importar
  # el certificado que tiene la propia Autofirma en el almacén de certificados de Firefox
  # y de Chrome. Para ello, primero es necesario copiar el certificado que se llama
  # AutoFirma_ROOT.cer y que se puede encontrar en /nix/store dentro del directorio donde
  # esté instalado autofirma.
  #
  # Instrucciones para Firefox:
  # En Settings, acceder a Certificados. Ir a pestaña Autoridades. Pulsa Importar... 
  # y selecciona el archivo AutoFirma_ROOT.cer. Importante: Marca las casillas 
  # "Confiar en esta CA para identificar sitios web".
  #
  # Instrucciones para Chrome:
  # Settings -> Privacy and Security -> Manage certificates -> Local certificates -> Custom
  # -> Installed by you -> Trusted certificates -> Import
  #
  # Normalmente, después de fallar una primera vez, a la siguiente que se intente la identificación
  # ya funcionará
}
