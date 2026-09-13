# Gemini / Antigravity Context for nixos-config

This repository manages multi-machine NixOS systems using Flakes and hosts the custom Hyprland-based desktop environment **SicOS**.

## 1. Project Architecture

- **`flake.nix`**: Entry point and outputs (`nixosConfigurations`, `nixosModules`, `homeManagerModules`).
- **`hosts/`**: Machine-specific configurations (`strange`, `rocket`, `ironman`, `taskmaster`, `vm`).
  - `default.nix`: Central logic using `mkHost` to generate configurations and define Stylix themes.
- **`modules/sicos/hyprland/`**: Core SicOS desktop environment module:
  - `default.nix`: System-level NixOS options, SDDM, packages, and system services.
  - `hm-module.nix`: Home Manager module managing dotfiles and Stylix integration.
  - `config-files/quickshell/`: Native QML desktop shell (SicOS-Bar, overlays, control center).
- **`home-manager/`**: User-specific dotfiles and helper scripts.

## 2. Specialized Skills (Required Usage)

Deep domain knowledge and procedural runbooks are organized into specialized skills under `.agents/skills/`. Agents **MUST** review the corresponding skill before modifying configurations:

- **Desktop UI, QuickShell & Theming:** Use [`.agents/skills/sicos-desktop/SKILL.md`](.agents/skills/sicos-desktop/SKILL.md)
  - Covers SicOS-Bar (QML), Premium UX rules, Wayland anchoring, Hyprland rules/bindings, Stylix theming, and Kanshi integration.
- **System Administration & Flakes:** Use [`.agents/skills/nixos-flake-ops/SKILL.md`](.agents/skills/nixos-flake-ops/SKILL.md)
  - Covers Flake rebuilds, host provisioning, hardware configurations, and Disko BTRFS partitioning.

## 3. General Rules & Code Style

- **Language:** All generated code, comments, user-facing UI labels, and commit messages must strictly be in English.
- **Existing Comments:** Never remove existing comments unless explicitly requested. Always place explanatory comments on the line immediately preceding the code.
- **Nix Formatting:** Standard 2-space indentation.
- **Dual-Script Synchronization:** Helper scripts duplicated in `home-manager/desktop/hyprland/scripts/` and `modules/sicos/hyprland/scripts/` must always be updated in both locations.
- **Nix Store Immutability:** Never attempt to edit files inside `/nix/store/` or symlinked store paths directly.
