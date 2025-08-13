# nixos-config
This repository gathers all the configuration needed to install NixOS on several machines using flakes. It is a work in progress.
I'm really new at NixOS and I want to experiment and learn about it step by step.

# Installation

- Boot the system using NixOS live USB
- Execute the installation script which is located in **scripts/install.sh**

      curl -sL https://raw.githubusercontent.com/egara/nixos-config/main/scripts/install.sh | bash -s <hostname> <username>
      

Please, change **hostname** and **username** by one of their accepted values:

- hostname: [vm, rocket-hyprland, rocket-plasma, ironman-hyprland, ironman-plasma]
- username: egarcia

This script will:

1. Clone this repository [https://github.com/egara/nixos-config.git](https://github.com/egara/nixos-config.git)
1. Format and create all the needed partitions using [Disko](https://github.com/nix-community/disko)
1. Install NixOS
1. Copy this repo into the new installed system

## Systems

There are three different systems defined in this flake. Each system can have one or multiple outputs (NixOS configurations).

### VM

This is intended to be installed on a virtual machine for testing purposes (a virtual machine created using KVM, QEMU, libvirt). This is the specific profile that **anyone will be able to use in order to provision a totally functional NixOS system without any modification**. So it is perfect to twinker. 

It will give you:

- A NixOS installation

- Desktop environment: **KDE Plasma Desktop**

- Spice guest additions for QEMU installed by default so you will have batteries included ready to go.

### Rocket

This is intended to be installed on a my old PC. Please, bear in mind that the configuration created here is very specific and depends on the hardware of this computer. You can see this hardware dependent configurations here [https://github.com/egara/nixos-config/blob/main/hosts/rocket/configuration.nix](https://github.com/egara/nixos-config/blob/main/hosts/rocket/configuration.nix) and here [https://github.com/egara/nixos-config/blob/main/hosts/rocket/hardware-configuration.nix](https://github.com/egara/nixos-config/blob/main/hosts/rocket/hardware-configuration.nix)

There are two different profiles:

- **rocket-plasma**

      It will give you:

            - A NixOS installation

            - Desktop environment: **KDE Plasma Desktop**

- **rocket-hyprland**

      It will give you:

            - A very advanced NixOS installation customized for Hyprland. Check all the extra packages installed here [https://github.com/egara/nixos-config/blob/main/modules/desktop/hyprland.nix](https://github.com/egara/nixos-config/blob/main/modules/desktop/hyprland.nix) to get a flawless experience with Hyprland

            - All the configuration files for the different pieces of software that contribute with this flawless experience via Home-Manager

            - Desktop environment: **Hyprland**

### Ironman

This is intended to be installed on my current laptop. Please, bear in mind that the configuration created here is very specific and depends on the hardware of this computer. You can see this hardware dependent configurations here [https://github.com/egara/nixos-config/blob/main/hosts/ironman/configuration.nix](https://github.com/egara/nixos-config/blob/main/hosts/ironman/configuration.nix) and here [https://github.com/egara/nixos-config/blob/main/hosts/ironman/hardware-configuration.nix](https://github.com/egara/nixos-config/blob/main/hosts/ironman/hardware-configuration.nix)

There are two different profiles:

- **ironman-plasma**

      It will give you:

            - A NixOS installation

            - Desktop environment: **KDE Plasma Desktop**

- **ironman-hyprland**

      It will give you:

            - A very advanced NixOS installation customized for Hyprland. Check all the extra packages installed here [https://github.com/egara/nixos-config/blob/main/modules/desktop/hyprland.nix](https://github.com/egara/nixos-config/blob/main/modules/desktop/hyprland.nix) to get a flawless experience with Hyprland

            - All the configuration files for the different pieces of software that contribute with this flawless experience via Home-Manager

            - Desktop environment: **Hyprland**

# Partitioning
This stage will be created automatically by **Disko**.

## VM

This is the selected layout for the UEFI/GPT system:

| Mount point | Partition | Partition type      | FS Type | Label | Bootable flag | Size |
|-------------|-----------|---------------------|---------|--------|------|------------|
| /boot/efi   | /dev/vda1 | EFI System Partition| FAT32   | UEFI   | Yes | 512 MiB     |
| [SWAP]      | /dev/vda2 | Linux swap 		  | SWAP    | swap   | No  | 1 GiB     |
| /           | /dev/vda3 | Linux 			  | BTRFS   | system | No  | Available |

## Rocket

This is the selected layout for the BIOS/MBR system:

| Mount point | Partition | Partition type      | FS Type | Label | Bootable flag | Size |
|-------------|-----------|---------------------|---------|--------|------|--------------|
| --          | /dev/sda1 | MBR                 | EF02    | --     | Yes   | 1 MiB       |
| /boot/      | /dev/sda2 | EF00                | VFAT    | --     | Yes   | 512 MiB     |
| /           | /dev/sda3 | Linux               | ext4    | system | No    | Available   |
| [SWAP]      | /dev/sda4 | Linux swap          | SWAP    | swap   | No    | 8 GiB       |

## Ironman

This is the selected layout for the UEFI/GPT system:

| Mount point | Partition | Partition type      | FS Type | Label | Bootable flag | Size |
|-------------|-----------|---------------------|---------|--------|------|-------------|
| /boot/efi   | /dev/sda1 | EFI System Partition| FAT32   | UEFI   | Yes  | 512 MiB     |
| [SWAP]      | /dev/sda2 | Linux swap            | SWAP    | swap   | No  | 16 GiB     |
| /           | /dev/sda3 | Linux                 | BTRFS   | system | No  | Available  |

# BTRFS Layout
This is the layout only defined all over my different machines which use BTRFS:

```
(Volume)
|
├─ @ (Subvolume - It will be the current /)
|
├─ @home (Subvolume -  It will be the current /home)
|
├─ @snapshots (Subvolume -  It will contain all the snapshots which are subvolumes too)
```

The whole volume will be mounted and available at **/mnt/defvol** once the system is installed.

# Resources
These are the resources I have used to get inspiration and learn a little bit about NixOs.

- Matthias Benaets on GitHub [https://github.com/MatthiasBenaets/nixos-config](https://github.com/MatthiasBenaets/nixos-config)
- Wimpy's World on GitHub [https://github.com/wimpysworld/nix-config](https://github.com/wimpysworld/nix-config)
- NixOS Tutorial and basic concepts on YouTube by Mathhias Benaets [https://www.youtube.com/watch?v=AGVXJ-TIv3Y](https://www.youtube.com/watch?v=AGVXJ-TIv3Y)
