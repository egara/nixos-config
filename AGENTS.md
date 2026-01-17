# OpenCode Agents for nixos-config

This document outlines the agents designed to understand and modify the `nixos-config` repository. This repository manages NixOS configurations for multiple machines using flakes and includes a custom desktop environment module called SicOS.

## General Rules

- All generated code and comments must be in English.
- Do not delete existing comments in the code.

## 1. Core Agents

### 1.1. `nixos_expert`

**Expertise:** General knowledge of the NixOS ecosystem, including flakes, modules, `nixpkgs`, and the Nix language.

**Chain of thought:**

1.  **Analyze the `flake.nix` file:** Identify the main inputs (e.g., `nixpkgs`, `home-manager`, `disko`, `stylix`), outputs (`nixosConfigurations`, `nixosModules`, `homeManagerModules`), and the overall structure.
2.  **Examine the `hosts` directory:** Understand how different machine configurations are defined and organized. Note the use of `default.nix` to generate configurations and the pattern of having specific directories for each host (e.g., `vm`, `rocket`, `ironman`).
3.  **Inspect the `modules` directory:** Identify the different custom modules being used, with a special focus on the `sicos` module.
4.  **Review the `home-manager` directory:** Understand how user-specific configurations (dotfiles) are managed and structured.

**File Paths:**

-   `nixos-config/flake.nix`
-   `nixos-config/hosts/`
-   `nixos-config/modules/`
-   `nixos-config/home-manager/`

### 1.2. `sicos_desktop_expert`

**Expertise:** Deep understanding of the SicOS module, a custom Hyprland-based desktop environment. This agent knows about the components, features, and configuration options of SicOS.

**Chain of thought:**

1.  **Start with the SicOS module definition:** Analyze `modules/sicos/hyprland/default.nix` to understand the main options (`enable`, `theming`, `powerManagement`, `insync`, `kanshi`, etc.) and how they are implemented.
2.  **Analyze the Home Manager module:** Review `modules/sicos/hyprland/hm-module.nix` to see how user-level configurations (dotfiles, services) are deployed.
3.  **Map the components:**
    *   **Hyprland (WM):** Check the configuration files in `modules/sicos/hyprland/config-files/`, such as `hyprland-with-kanshi.conf`.
    *   **Waybar (Status Bar):** Examine the different `config.jsonc` and `style.css` files under `modules/sicos/hyprland/config-files/waybar/`. Note the conditional configurations based on `powerManagement` and `insync`.
    *   **Stylix (Theming):** Look at `modules/sicos/hyprland/hm-module.nix` to see how `stylix` is used for theming and how `light` and `dark` modes are configured.
    *   **Power Management:** Analyze `modules/sicos/hyprland/power-management.nix` and the associated scripts to understand the automatic power profile switching.
    *   **Application Launcher (Walker):** Check the `walker` configurations in `modules/sicos/hyprland/config-files/walker/`.
    *   **Other tools:** Review configurations for `hyprlock`, `hypridle`, `wlogout`, `swaync`, `swappy`, etc.
4.  **Understand the scripts:** Analyze the scripts in `modules/sicos/hyprland/scripts/` to understand their functionality (e.g., `nixos-clean.sh`, `nixos-scripts.sh`).

**File Paths:**

-   `nixos-config/modules/sicos/hyprland/default.nix` (Main module)
-   `nixos-config/modules/sicos/hyprland/hm-module.nix` (Home Manager module)
-   `nixos-config/modules/sicos/hyprland/config-files/` (Component configurations)
-   `nixos-config/modules/sicos/hyprland/scripts/` (Helper scripts)
-   `nixos-config/modules/sicos/hyprland/power-management.nix`
-   `nixos-config/modules/sicos/hyprland/insync-integration.nix`

### 1.3. `theme_switcher_expert`

**Expertise:** Specialized knowledge of the theme switching mechanism within the `nixos-config` repository, particularly for the SicOS module.

**Chain of thought:**

1.  **Locate the theme switching script:** The primary entry point is `home-manager/desktop/hyprland/scripts/theme-switcher.sh`.
2.  **Analyze the script's logic:**
    *   It takes `light` or `dark` as an argument.
    *   It searches for the NixOS configuration file that defines `theming.mode`.
    *   It uses `sed` to replace the value of `theming.mode`.
    *   It triggers a `nixos-rebuild switch` to apply the changes.
3.  **Trace the theme application:**
    *   Follow the `theming.mode` option in `modules/sicos/hyprland/default.nix`.
    *   See how it conditionally selects configurations, especially for `stylix` in `modules/sicos/hyprland/hm-module.nix`.
    *   Note how `stylix` applies the theme to different targets like `kitty` and `gtk`.
    *   Investigate how `walker`'s theme is switched in `modules/sicos/hyprland/default.nix` based on `theming.mode`.

**File Paths:**

-   `nixos-config/home-manager/desktop/hyprland/scripts/theme-switcher.sh` (Primary script)
-   `nixos-config/modules/sicos/hyprland/hm-module.nix` (Stylix theme application)
-   `nixos-config/modules/sicos/hyprland/default.nix` (Option definition and conditional logic)
-   `nixos-config/hosts/default.nix` (Where `theming.mode` is ultimately set)

## 2. Orchestrator Agent

### `nixos_config_orchestrator`

This agent coordinates the other agents to fulfill complex tasks.

**Chain of thought (Example Task: "Add a new color to the light theme"):**

1.  **Goal:** Add a new color definition to be used in the light theme.
2.  **Consult `theme_switcher_expert`:** Ask for the primary file that defines the light theme colors. The expert should identify that `stylix` is used and the base scheme is defined in `modules/sicos/hyprland/hm-module.nix` pointing to a `base16-schemes` file.
3.  **Consult `sicos_desktop_expert`:** Ask where this new color should be applied. For instance, if the user wants to change the Waybar background, this agent knows to look in `modules/sicos/hyprland/config-files/waybar/powermanagement/style.css` (or the `no-powermanagement` variant) and can suggest how to use the new `stylix` variable.
4.  **Consult `nixos_expert`:** Once the changes are made, this agent knows that a `nixos-rebuild switch --flake .#<host-profile>` is required to apply the changes system-wide.
5.  **Synthesize and Execute:**
    *   Modify the `stylix` configuration in `modules/sicos/hyprland/hm-module.nix` if a new base16 color is needed.
    *   Modify the component's CSS or config file (e.g., `waybar/style.css`) to use the new color variable.
    *   Execute the rebuild command to apply the theme.

## 3. Personas

### Persona: NixOS System Administrator

-   **Description:** A user who is comfortable with the Nix language and the structure of this repository. They want to make changes to system configurations, manage packages, or update modules.
-   **Example Prompt:** "Add the `htop` package to the `ironman-hyprland` host configuration."
-   **Agent to use:** `nixos_expert` would be the primary agent. It would know to edit `hosts/ironman/configuration.nix` or the shared `hosts/configuration.nix` to add `pkgs.htop` to the `environment.systemPackages` list.

### Persona: Desktop Customizer

-   **Description:** A user who wants to tweak the look and feel of the SicOS desktop environment. They are likely less concerned with the underlying NixOS structure and more with theming, keybindings, and application appearance.
-   **Example Prompt:** "Change the keybinding for opening the terminal to `Super + Enter`."
-   **Agent to use:** `sicos_desktop_expert` is the perfect agent. It would identify that keybindings are managed in `modules/sicos/hyprland/config-files/hyprland-with-kanshi.conf` and modify the corresponding `bindd` line.

### Persona: Theme Developer

-   **Description:** A user focused specifically on the color schemes and overall aesthetic of the light and dark themes.
-   **Example Prompt:** "The text in the light theme for Walker is hard to read. Make it darker."
-   **Agent to use:** `theme_switcher_expert` would be the main agent. It would identify that `walker`'s light theme is configured in `modules/sicos/hyprland/config-files/walker/themes/sicos-light/style.css` and would adjust the `color` property for the appropriate CSS selector.
