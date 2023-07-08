# nixos-config
This repository gathers all the configuration needed to install NixOS on several machines using flakes

# Installation

- Boot the system using NixOS live USB
- Execute the installation script which is located in **scripts/install.sh**

      curl -sL https://raw.githubusercontent.com/egara/nixos-config/main/scripts/install.sh | bash -s <hostname> <username>
      

Please, change **hostname** and **username** by one of their accepted values:

- hostname: vm
- username: egarcia

This script will:

1. Clone this repository [https://github.com/egara/nixos-config.git](https://github.com/egara/nixos-config.git)
1. Format and create all the needed partitions using [Disko](https://github.com/nix-community/disko)
1. Install NixOS
1. Copy this repo into the new installed system

# Partitioning
This stage will be created automatically by **Disko**.

## VM

This is the selected layout for the UEFI/GPT system:

| Mount point | Partition | Partition type      | FS Type | Label | Bootable flag | Size |
|-------------|-----------|---------------------|---------|--------|------|--|
| /boot/efi   | /dev/vda1 | EFI System Partition| FAT32   | UEFI   | Yes | 512 MiB   |
| [SWAP]      | /dev/vda2 | Linux swap 		  | SWAP    | swap   | No  | 1 GiB     |
| /           | /dev/vda3 | Linux 			  | BTRFS   | system | No  | Available |

