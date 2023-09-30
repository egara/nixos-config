# Bootloader configuration for EFI systems

{ config, pkgs, inputs, username, ... }:

{
  # Bootloader
  boot.loader = {
    timeout = 3;

    grub = {
      enable = true;
      device = "/dev/sda";
      efiSupport = true;
      efiInstallAsRemovable = true;
      configurationLimit = 3;
      theme = pkgs.nixos-grub2-theme;
    };
  };
}
