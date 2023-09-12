# Bootloader configuration for EFI systems

{ config, pkgs, inputs, username, ... }:

{
  # Bootloader
  boot.loader = {
    timeout = 3;

    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };

    grub = {
      enable = true;
      devices = ["nodev"];
      efiSupport = true;
      configurationLimit = 3;
      theme = pkgs.nixos-grub2-theme;
    };
  };
}
