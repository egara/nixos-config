# Gemini Agent Context for nixos-config

This document serves as the primary context and knowledge base for the Gemini CLI agent operating within the `nixos-config` repository. It outlines the project's architecture, key components, and operational workflows.

## 1. Project Philosophy & Goal

This repository is a **NixOS Flake** configuration that manages multiple machines (hosts). The primary goal is to provide a reproducible, declarative system configuration with a focus on a custom, polished desktop environment named **SicOS**.

**Core Principles:**
- **Pure Flakes:** All configurations are driven by `flake.nix`.
- **Modularity:** Configuration is split into `hosts`, `modules` (system-level), and `home-manager` (user-level).
- **SicOS:** A custom Hyprland-based desktop environment module that can be imported by any NixOS system.
- **Theming:** Integrated Light/Dark mode switching using **Stylix** and a custom theme switcher.

## 2. Architecture & Directory Structure

- **`flake.nix`**: The entry point. Defines inputs (NixOS, Home Manager, Stylix, etc.) and outputs (`nixosConfigurations`, `nixosModules`, `homeManagerModules`).
- **`hosts/`**: Contains machine-specific configurations.
    - `default.nix`: **Central logic** using `mkHost` to generate configurations. Defines `themeMode` and `themeScheme` for SicOS.
    - `<hostname>/`: Directory for each machine (e.g., `ironman`, `rocket`, `strange`, `vm`, `taskmaster`).
        - `configuration.nix`: Main system configuration for the host.
        - `hardware-configuration.nix`: Hardware-specific settings.
        - `disko-config.nix`: Disk partitioning layout (managed by Disko).
- **`modules/`**: Custom NixOS modules.
    - `sicos/hyprland/`: **The core SicOS module.** Highly modular and configurable.
        - `default.nix`: Defines extensive module options (`programs.sicos.hyprland.*`) and system-level config (SDDM, packages, portals).
        - `hm-module.nix`: Home Manager companion module. Manages dotfiles via dynamic Nix templates and integrates with **Stylix**.
        - `config-files/`: Raw configuration templates (Waybar, SwayNC, Wlogout, etc.).
        - `scripts/`: Helper scripts like `sicos-settings.sh` and `screensaver.sh`.
        - `themes/`: Predefined color schemes and previews.
        - `wallpapers/`: Curated wallpapers for light/dark modes.
        - `sddm-theme/`: Custom SicOS theme for the SDDM login manager.
- **`home-manager/`**: User-specific configurations (dotfiles) and shared resources used by the SicOS module.
    - `desktop/hyprland/scripts/theme-switcher.sh`: The master script for toggling themes and rebuilding the system.

## 3. Key Components

### 3.1. SicOS Module
**Location:** `modules/sicos/hyprland/`

SicOS provides a complete, themed desktop experience. It is split into two parts:
1.  **NixOS Module (`default.nix`)**:
    - Installs a wide range of packages (`hyprland`, `hyprlock`, `hypridle`, `waybar`, `swaynotificationcenter`, `wlogout`, `walker`, etc.).
    - Enables system services (`sddm` with custom theme, `gvfs`, `udisks2`, `polkit`).
    - Defines options to overwrite default configs for Waybar, Wlogout, SwayNC, etc.
2.  **Home Manager Module (`hm-module.nix`)**:
    - Manages dotfiles in `.config/hypr`, `.config/waybar`, `.config/swaync`, etc.
    - Uses dynamic `.text` generation for Waybar, Wlogout, and SwayNC styles to integrate Stylix colors.
    - Configures `xdg.mimeApps` for default applications (Zed, Firefox, Thunar, etc.).
    - Integrates with **Stylix** for global theming.

**Key Options:**
- `enable`: Activate the module.
- `theming.mode`: `"light"` or `"dark"`.
- `theming.base16Scheme`: Base16 color scheme name (e.g., `"catppuccin-mocha"`).
- `powerManagement.enable`: System optimizations and Waybar power modules.
- `kanshi.enable`: Automated monitor layout management.
- `insync.enable`: Google Drive sync integration.

### 3.2. Theming & Stylix
Theming is a core feature of SicOS, managed by **Stylix** and the `theme-switcher.sh` script.
- **Stylix Integration**: Defined in `hm-module.nix`. It sets colors, fonts (JetBrainsMono Nerd Font), and cursors (Bibata) globally. It handles polarity (light/dark) and targets various apps (Kitty, Zed, Btop, Yazi).
- **Theme Switcher Script**:
    1.  Located at `home-manager/desktop/hyprland/scripts/theme-switcher.sh`.
    2.  Updates `themeMode` and `themeScheme` in `hosts/default.nix` using `sed`.
    3.  Runs `nixos-rebuild switch --flake .#<host>-hyprland`.
    4.  Restarts UI services (`waybar`, `swaync`, `walker`) using `uwsm app` to apply changes instantly.
    5.  Updates the wallpaper using `awww`.

### 3.3. Hosts
- **VM (`vm`)**: Virtual machine for testing (Plasma/Hyprland).
- **Rocket (`rocket`)**: Desktop PC (Nvidia/AMD).
- **Ironman (`ironman`)**: Laptop (Intel/Nvidia).
- **Taskmaster (`taskmaster`)**: Work Laptop.
- **Strange (`strange`)**: Framework Laptop 13 (AMD Ryzen AI 300).

## 4. Operational Workflows for the Agent

### 4.1. Modifying the Desktop Environment (SicOS)
**Goal:** Change UI components or behavior.
1.  **Identify Component:**
    - System packages or global services: Edit `modules/sicos/hyprland/default.nix`.
    - User config or dynamic styles: Edit `modules/sicos/hyprland/hm-module.nix` or the corresponding `.nix` template in `config-files/`.
2.  **Edit Config:**
    - Waybar: `modules/sicos/hyprland/config-files/waybar/waybar-style.nix`.
    - Hyprland: `home-manager/desktop/hyprland/config/hyprland.conf`.
3.  **Apply:** Run `nixos-rebuild switch --flake .#<host>-hyprland`.

### 4.2. Adding a New Package
- **System-wide:** Add to `environment.systemPackages` in `modules/sicos/hyprland/default.nix` (if SicOS-related) or `hosts/<host>/configuration.nix`.
- **User-specific:** Add to `home.packages` in `hosts/home.nix`.

### 4.3. Creating a New Host
1.  Create `hosts/<new-host>/`.
2.  Add `hardware-configuration.nix`, `configuration.nix`, and `disko-config.nix`.
3.  Update `hosts/default.nix` to add a new `mkHost` entry in the `in { ... }` block.

## 5. File Map

| Path | Description |
| :--- | :--- |
| `flake.nix` | Entry point, inputs, and module exports. |
| `hosts/default.nix` | Central host generator and SicOS settings. |
| `modules/sicos/hyprland/default.nix` | SicOS System Module (Packages, SDDM, Options). |
| `modules/sicos/hyprland/hm-module.nix` | SicOS Home Manager Module (Stylix, Dotfiles). |
| `modules/sicos/hyprland/config-files/` | Configuration templates (Nix-based CSS/JSON). |
| `home-manager/desktop/hyprland/scripts/` | User-space scripts (theme switcher, etc.). |

## 6. General Rules & Style Guide

### 6.1. General Rules
- **Language:** All generated code and comments must be in English.
- **Existing Comments:** Do not delete existing comments in the code.
- **Comment Placement:** All comments must be placed on the line immediately preceding the code they describe.

### 6.2. Style Guidelines
- **Nix Formatting:** Use standard formatting (2 spaces indentation).
- **Comments Content:** Explain *why* something is done, not just *what* is done.
- **Commit Messages:** Use clear, concise messages (e.g., `feat(sicos): add screensaver script`).
