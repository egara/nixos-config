# nixos-config
This repository gathers all the configuration needed to install NixOS on several machines using flakes

# Installation

- Boot the system using NixOS live USB
- Edit **/etc/nixos/configuration.nix**

    sudo edit /etc/nixos/configuration.nix

- Enable nix-command and flakes experimental features:

'''
      experimental-features = [
        "nix-command"
        "flakes"
      ];
'''

- Apply the new configuration:


    sudo nixos-rebuild switch

- Identify the name of your system disk by using the **lsblk** command as follows:

    lsblk

- Get  **disko-config.nix** file for the specific host:

    cd /tmp
    curl https://raw.githubusercontent.com/egara/nixos-config/main/hosts/disko-config.nix -o disko-config.nix

- Execute the configuration. The following step will partition and format your disk, and mount it to /mnt. Replace <disk-name> with the name of your disk obtained previously:

    sudo nix run github:nix-community/disko -- --mode disko /tmp/disko-config.nix --arg disks '[ "/dev/<disk-name>" ]'

- Open Gparted and label the partitions which don't have it assigned (UEFI, swap and system).

- Clone nixos-config repo and install NixOS. Replace <host> for the name of the host selected (f.i. vm):

    cd /mnt
    git clone https://github.com/egara/nixos-config.git
    cd nixos-config
    nixos-install --flake .#<host>
    sudo reboot
