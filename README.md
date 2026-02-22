# nixos-config
This repository gathers all the configuration needed to install NixOS on several machines using flakes. It also provides **SicOS**, a complete Hyprland-based desktop environment module for any NixOS flake-based system. It is a work in progress.

# SicOS Desktop Environment

SicOS is a complete desktop environment based on [Wayland](https://wayland.freedesktop.org/) and the [Hyprland](https://hyprland.org/) tiling compositor. It is provided as a NixOS module that simplifies its installation and setup, allowing users to enjoy a functional and customizable desktop experience out of the box.

This module handles the installation and configuration of all necessary components, including the status bar (Waybar), application launcher (Walker), notification manager (swaync), screen locker (hyprlock), and much more.

## Features

- **Power Management**: If activated, this option is ideal for laptops. It provides three power profiles (`performance`, `balanced`, and `power-saver`). The system automatically switches to `power-saver` mode when the AC adapter is disconnected and returns to `balanced` mode when reconnected.

- **Default Hyprland Keybindings**: A sensible set of default keybindings for common actions is included:
  - `Mod + Q`: Close the active window.
  - `Mod + E`: Launch the file manager.
  - `Mod + F`: Toggle floating mode for a window.
  - `Ctrl + Alt + T`: Launch a terminal.
  - `Mod + Arrow Keys`: Move focus between windows.

- **Audible and Visual Feedback**: Get instant feedback when adjusting system settings:
  - **Volume Control**: A notification and a sound effect are triggered when you raise or lower the volume.
  - **Brightness Control**: A notification visually indicates the new screen brightness level.

- **SicOS settings menu**: Press `Mod + S` to open a menu with a basic SicOS settings menu. By default, it includes:
  - A script to clean the system by removing old NixOS generations and garbage-collecting unused store paths.
  - A wallpaper selector tool to pick any official wallpaper included. Those wallpapers are located in ~/.config/sicos/wallpapers and new wallpapers can be added an automatically recognized here.

- **Wallpaper Management**: A collection of wallpapers is included in `modules/sicos/hyprland/wallpapers/`. You can press `Mod + 1` to randomly switch between them too.

- **Insync Integration**: Due to rendering issues with the official Insync tray icon in some Wayland environments, this module provides a custom Waybar integration that displays the current sync status.

- **Light & Dark Mode Theming**: The module offers full system integration for both light and dark themes via **Stylix**. It automatically switches wallpapers, icons, cursors, and configuration files for all components (Waybar, Walker, Wlogout, Swaync, etc.) to ensure a consistent and beautiful look in either mode.

- **base16Scheme**: The module offers full system integration for color base16Scheme via Stylix too. More information below.

## Prerequisites

- **Flake-based System**: Your NixOS system must be configured to use **flakes**.

- **Desktop Environment Conflicts**: If your existing NixOS configuration defines another desktop environment (e.g., GNOME, Plasma, XFCE), you must comment out or remove those configurations. SicOS provides its own desktop environment based on Hyprland, and conflicting definitions can lead to issues.

  *Example (in `configuration.nix` or a similar module):*
  ```nix
  # services.desktopManager.plasma6.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;
  ```

- **Display Manager Conflicts**: The SicOS module enables SDDM by default. If you have another display manager configured (e.g., GDM, LightDM), you must comment out or remove its configuration to avoid conflicts.

  *Example (in `configuration.nix` or a similar module):*
  ```nix
  # services.xserver.displayManager.gdm.enable = true;
  # services.displayManager.lightdm.enable = true;
  ```

## How to Use

To enable SicOS in your NixOS configuration, you need to add the `nixos-config` flake as an input in your `flake.nix` and import the `nixosModules.sicos-hyprland` and `homeManagerModules.sicos-hyprland` modules.

Below is a complete example of a `flake.nix` file:

```nix
{
  description = "My NixOS Flake Configuration using the remote sicos module";

  inputs = {
    # 1. NixOS Unstable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # 2. Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # 3. SicOS Module from GitHub
    sicos-config = {
      url = "github:egara/nixos-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, sicos-config, ... }@inputs:
  let
    # Set the username for the system configuration
    username = "egarcia";
  in
  {
    nixosConfigurations = {
      # Change 'my-nixos-pc' to your system's hostname
      "my-nixos-pc" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # Adjust if you use ARM (aarch64-linux)
        
        # Pass inputs to modules so they can use them
        specialArgs = { inherit inputs; };

        modules = [
          # Import your existing hardware-configuration.nix and configuration.nix here
          ./hardware-configuration.nix
          ./configuration.nix

          # Import the NixOS module for SicOS and enable the desired options
          sicos-config.nixosModules.sicos-hyprland
          {
            programs.sicos.hyprland = {
              enable = true; # Enable SicOS
              theming.enable = true; # Enable default theming (recommended)
              theming.mode = "dark"; # Set theme mode to dark or light
              theming.base16Scheme = "catppuccin-mocha"; # Set theme base16 schema
              powerManagement.enable = true; # Enable power management for laptops
              insync.enable = true; # Enable Insync integration
              kanshi.enable = true; # Enable monitor profile management
              waybar.overwrite = false; #Set the default waybar configurations for SicOS
            };
          }

          # Import the Home Manager module
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            
            # Configure Home Manager for the specified user
            home-manager.users.${username} = { pkgs, ... }: {
              # Import the Home Manager module for SicOS
              imports = [ sicos-config.homeManagerModules.sicos-hyprland ];
              home.stateVersion = "23.11"; # Or your corresponding version
            };
          }
        ];
      };
    };
  };
}
```

## Module Options

The SicOS module offers several options to customize your environment. All options are located under the `programs.sicos.hyprland` namespace.

| Option | Type | Default Value | Description |
| --- | --- | --- | --- |
| `enable` | boolean | `false` | Enables or disables the SicOS module entirely. |
| `theming.enable` | boolean | `true` | Enables theme configuration (GTK, Qt, icons, cursors) through Home Manager and Stylix. |
| `theming.mode` | string | `"dark"` | Sets the theme to either `"dark"` or `"light"`. |
| `theming.base16Scheme` | string | `"catppuccin-mocha"` | Selects the Base16 color scheme for Stylix. It can be set to `catppuccin-mocha`, `equilibrium-light`, `everforest`, `gruvbox-dark`, `gruvbox-light-soft` and many more. Plese, read **Note on Theming** for more information |
| `powerManagement.enable` | boolean | `true` | Enables power management for laptops, using `power-profiles-daemon` and automatically adjusting brightness and power profiles when plugging/unplugging the AC adapter. |
| `insync.enable` | boolean | `false` | Enables integration with Insync, including a Waybar status indicator. |
| `insync.package` | package | `pkgs.insync` | Allows specifying a different Insync package version (e.g., from `pkgs-stable`). |
| `kanshi.enable` | boolean | `false` | Enables [Kanshi](https://sr.ht/~emersion/kanshi/) for automatic monitor profile management. Requires a custom configuration file. |
| `hyprland.configFile` | path | Depends on `kanshi.enable` | Path to the `hyprland.conf` file. The module selects a default file that enables `kanshi` if it is active. |
| `hyprlock.configFile` | path | Internal file | Path to the `hyprlock.conf` file. |
| `hyprlock.profilePicture` | path | Internal file | Path to the profile picture displayed on the lock screen. |
| `hypridle.configFile` | path | Internal file | Path to the `hypridle.conf` file for idle management. |
| `waybar.overwrite` | boolean | `false` | It allows the user to overwrite waybar's configFile and styleFile with custom files designed by the user. It it is set to false, Waybar will be set to the stock SicOS configurations and the look and feel will be dynamic and depend on the theming.base16Scheme selected |
| `waybar.configFile` | path | Internal file | Path to Waybar's `config.jsonc` file. **It must be provided by the user if waybar.overwrite option is set to true.** |
| `waybar.styleFile` | path | Internal file | Path to Waybar's `style.css` file. **It must be provided by the user if waybar.overwrite option is set to true.** |
| `wlogout.layoutFile` | path | Internal file | Path to the `wlogout` layout file (shutdown menu). |
| `wlogout.styleFile` | path | Internal file | Path to the `wlogout` style file. |
| `swaync.configFile` | path | Internal file | Path to the `config.json` file for the `swaync` notification center. |
| `swaync.styleFile` | path | Internal file | Path to the `style.css` file for `swaync`. |
| `kanshi.configFile` | path | Internal (empty) file | Path to the `kanshi` configuration file. **You must override this with your own monitor setup.** |
| `walker.configFile` | path | Internal file | Path to the `config.toml` file for the `walker` application launcher. |
| Scripts | `programs.sicos.hyprland.scripts.path` | [scripts/](https://github.com/egara/nixos-config/tree/main/modules/sicos/hyprland/scripts) |

> **Note on Theming:** The `theming.base16Scheme` option uses [Base16](https://github.com/chriskempson/base16) schemes to style the system via Stylix. You can preview these schemes at the [Tinted Theming Gallery](https://tinted-theming.github.io/tinted-gallery/). Currently, only base16 schemes are supported to ensure a cohesive look. If you want to know the meaning of all the different colors within a base16Scheme you can check the official documentation [https://github.com/chriskempson/base16/blob/main/styling.md](https://github.com/chriskempson/base16/blob/main/styling.md).

## Theme Switching Script

Included in this repository is a script named [`theme-switcher.sh`](https://github.com/egara/nixos-config/blob/main/home-manager/desktop/hyprland/scripts/theme-switcher.sh), located in `home-manager/desktop/hyprland/scripts/`.

**Note:** This script is **not** part of the core SicOS module because it relies on specific paths and configurations unique to my personal setup (e.g., the location of the flake configuration). However, it is provided here as a reference and inspiration for users who wish to implement similar functionality in their own environments.

The script automates the process of switching between "light" and "dark" themes as well as the base16 scheme selected by performing the following steps:

1. **Locates the Configuration:** Finds the relevant NixOS configuration file containing the `themeMode` setting.
2. **Updates the Theme:** Modifies the configuration file to set the desired theme (`light` or `dark`).
3. **Updates the Scheme:** Modifies the configuration file to set the desired basic16Scheme.
4. **Rebuilds the System:** Executes `nixos-rebuild switch` to apply the changes system-wide.
5. **Restarts Services:** Refreshes UI components like Waybar, SwayNC, and Walker to reflect the new theme immediately.
6. **Updates Wallpaper:** Changes the desktop wallpaper to match the selected theme.

Feel free to adapt this script to fit your own configuration structure!

## Customization

One of the advantages of this module is that you can easily override any configuration file to suit your needs. Simply define the path to your custom file in your `flake.nix`.

Below is a table with the components you can customize and a link to their default configuration in the repository.

| Component | Option to Override | Default Configuration File |
| --- | --- | --- |
| Hyprland | `programs.sicos.hyprland.hyprland.configFile` | [hyprland.conf](https://github.com/egara/nixos-config/blob/main/modules/sicos/hyprland/config-files/hyprland-with-kanshi.conf) |
| Hyprlock | `programs.sicos.hyprland.hyprlock.configFile` | [hyprlock.conf](https://github.com/egara/nixos-config/blob/main/modules/sicos/hyprland/config-files/hyprlock.conf) |
| Hypridle | `programs.sicos.hyprland.hypridle.configFile` | [hypridle.conf](https://github.com/egara/nixos-config/blob/main/modules/sicos/hyprland/config-files/hypridle.conf) |
| wlogout (layout) | `programs.sicos.hyprland.wlogout.layoutFile` | [layout](https://github.com/egara/nixos-config/blob/main/modules/sicos/hyprland/config-files/wlogout/layout) |
| wlogout (style) | `programs.sicos.hyprland.wlogout.styleFile` | [style.css](https://github.com/egara/nixos-config/blob/main/modules/sicos/hyprland/config-files/wlogout/style.css) |
| Swaync (config) | `programs.sicos.hyprland.swaync.configFile` | [config.json](https://github.com/egara/nixos-config/blob/main/modules/sicos/hyprland/config-files/swaync/config.json) |
| Swaync (style) | `programs.sicos.hyprland.swaync.styleFile` | [style.css](https://github.com/egara/nixos-config/blob/main/modules/sicos/hyprland/config-files/swaync/style.css) |
| Kanshi | `programs.sicos.hyprland.kanshi.configFile` | [config](https://github.com/egara/nixos-config/blob/main/modules/sicos/hyprland/config-files/kanshi/config) |
| Walker | `programs.sicos.hyprland.walker.configFile` | [config.toml](https://github.com/egara/nixos-config/blob/main/modules/sicos/hyprland/config-files/walker/config.toml) |
| Scripts | `programs.sicos.hyprland.scripts.path` | [scripts/](https://github.com/egara/nixos-config/tree/main/modules/sicos/hyprland/scripts) |

### Customization Example

If you want to use your own configuration file for Hyprland, simply add the following line to your `flake.nix` within the module's configuration section:

```nix
programs.sicos.hyprland = {
  enable = true;
  # ... other options
  hyprland.configFile = ./my-custom-hyprland.conf;
};
```

# NixOS System Configurations

This section details the pre-defined system configurations available in this repository.

## Installation

- Boot the system using a NixOS live USB.
- Execute the installation script located in **scripts/install.sh**.

      curl -sL https://raw.githubusercontent.com/egara/nixos-config/main/scripts/install.sh | bash -s <host> <profile> <username>
      

Please, change **host**, **profile**, and **username** to one of their accepted values:

- **host**: [`vm`, `rocket`, `ironman`, `taskmaster`, `strange`]
- **profile**: [`vm`, `rocket-plasma`, `rocket-hyprland`, `rocket-cosmic`, `ironman-plasma`, `ironman-hyprland`, `taskmaster-plasma`, `taskmaster-hyprland`, `strange-hyprland`]
- **username**: `egarcia` (this is the default value if omitted)

This script will:

1. Clone this repository [https://github.com/egara/nixos-config.git](https://github.com/egara/nixos-config.git)
2. Format and create all the needed partitions using [Disko](https://github.com/nix-community/disko)
3. Install NixOS
4. Copy this repo into the newly installed system

## Available Systems

There are several systems defined in this flake. Each system can have one or multiple outputs (NixOS configurations).

### VM

This is intended to be installed on a virtual machine for testing purposes. This is the specific profile that **anyone will be able to use in order to provision a totally functional NixOS system without any modification**. It is perfect for tinkering.

-   **Desktop environment**: KDE Plasma
-   **Features**: Spice guest additions for QEMU are installed by default for a seamless out-of-the-box experience.

### Rocket

This is intended for an old custom-built PC. The configuration is very specific to its hardware.

-   **Desktop environments**: `plasma`, `hyprland`, `cosmic`.

### Ironman

This is intended for an older laptop. The configuration is very specific to its hardware (Intel Core i7 6700HQ, Nvidia GTX 960M).

-   **Desktop environments**: `plasma`, `hyprland`.
-   **Note**: This configuration uses an older kernel version (`6.1`) and specific kernel parameters for hardware compatibility.

### Taskmaster

This is a work laptop configuration with a static IP address and work-related software.

-   **Desktop environments**: `plasma`, `hyprland`.

### Strange

This is a **Framework Laptop 13 (AMD Ryzen AI 300 Series)** configuration. It uses the `nixos-hardware` flake for optimal support.

-   **Desktop environments**: `hyprland`.

## Partitioning Layouts

This stage is created automatically by **Disko**.

### VM

This is the selected layout for a UEFI/GPT system:

| Mount point | Partition | Partition type      | FS Type | Label | Bootable flag | Size |
|-------------|-----------|---------------------|---------|--------|------|------------|
| /boot/efi   | /dev/vda1 | EFI System Partition| FAT32   | UEFI   | Yes | 512 MiB     |
| [SWAP]      | /dev/vda2 | Linux swap 		  | SWAP    | swap   | No  | 4 GiB     |
| /           | /dev/vda3 | Linux 			  | BTRFS   | system | No  | Available |

### Rocket

This is the selected layout for a BIOS/MBR system:

| Mount point | Partition | Partition type      | FS Type | Label | Bootable flag | Size |
|-------------|-----------|---------------------|---------|--------|------|--------------|
| --          | /dev/sda1 | MBR                 | EF02    | --     | Yes   | 1 MiB       |
| /boot/      | /dev/sda2 | EF00                | VFAT    | --     | Yes   | 512 MiB     |
| /           | /dev/sda3 | Linux               | ext4    | system | No    | Available   |
| [SWAP]      | /dev/sda4 | Linux swap          | SWAP    | swap   | No    | 8 GiB       |

### Ironman

This is the selected layout for a UEFI/GPT system:

| Mount point | Partition | Partition type      | FS Type | Label | Bootable flag | Size |
|-------------|-----------|---------------------|---------|--------|------|-------------|
| /boot/efi   | /dev/sda1 | EFI System Partition| FAT32   | UEFI   | Yes  | 512 MiB     |
| [SWAP]      | /dev/sda2 | Linux swap            | SWAP    | swap   | No  | 16 GiB     |
| /           | /dev/sda3 | Linux                 | BTRFS   | system | No  | Available  |

### Taskmaster

This is the selected layout for a UEFI/GPT system (`/dev/nvme0n1`):

| Mount point | Partition | Partition type      | FS Type | Label | Bootable flag | Size |
|-------------|-----------|---------------------|---------|--------|------|-------------|
| /boot/efi   | /dev/nvme0n1p1 | EFI System Partition| FAT32   | UEFI   | Yes  | 512 MiB     |
| [SWAP]      | /dev/nvme0n1p3 | Linux swap            | SWAP    | swap   | No  | 32 GiB     |
| /           | /dev/nvme0n1p2 | Linux                 | BTRFS   | system | No  | Available  |

### Strange

This is the selected layout for a UEFI/GPT system (`/dev/nvme0n1`):

| Mount point | Partition | Partition type      | FS Type | Label | Bootable flag | Size |
|-------------|-----------|---------------------|---------|--------|------|-------------|
| /boot/efi   | /dev/nvme0n1p1 | EFI System Partition| FAT32   | UEFI   | Yes  | 512 MiB     |
| [SWAP]      | /dev/nvme0n1p3 | Linux swap            | SWAP    | swap   | No  | 16 GiB     |
| /           | /dev/nvme0n1p2 | Linux                 | BTRFS   | system | No  | Available  |

# BTRFS Layout
This is the layout defined for all machines which use BTRFS:

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
These are the resources I have used to get inspiration and learn a little bit about NixOS.

- Matthias Benaets on GitHub [https://github.com/MatthiasBenaets/nixos-config](https://github.com/MatthiasBenaets/nixos-config)
- Wimpy's World on GitHub [https://github.com/wimpysworld/nix-config](https://github.com/wimpysworld/nix-config)
- NixOS Tutorial and basic concepts on YouTube by Matthias Benaets [https://www.youtube.com/watch?v=AGVXJ-TIv3Y](https://www.youtube.com/watch?v=AGVXJ-TIv3Y)
