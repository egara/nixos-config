---
name: sicos-desktop
description: >
  REQUIRED for end-user customization, UI components, or configuration of the SicOS desktop environment.
  Use when editing QuickShell QML components, Hyprland configuration, Stylix theming, base16 schemes,
  desktop scripts, keybindings, wallpapers, or display settings.
  Triggers: SicOS, sicos-bar, quickshell, hyprland, waybar, stylix, theme-switcher, awww, kanshi,
  monitors, window rules, keybindings, control center, window switcher, window killer, wallpapers.
---

# SicOS Desktop Environment Skill

Manage and customize [SicOS](https://github.com/egara/nixos-config) - a custom, high-end Hyprland desktop environment module configured via NixOS Flakes, styled dynamically with Stylix, and powered by a native QuickShell UI shell (SicOS-Bar).

This skill applies to end-user customization and module development for the desktop environment components.

## When This Skill MUST Be Used

**ALWAYS invoke this skill for requests involving ANY of these:**

- Editing any QuickShell QML component in `modules/sicos/hyprland/config-files/quickshell/`
- Editing Hyprland configuration in `home-manager/desktop/hyprland/config/`
- Changing desktop themes, Base16 schemes, fonts, or wallpapers
- Adjusting keybindings, window rules, animations, blur, gaps, or borders
- Modifying display settings, monitor scale, or Kanshi profiles
- Modifying desktop helper scripts in `home-manager/desktop/hyprland/scripts/` or `modules/sicos/hyprland/scripts/`
- Customizing desktop overlays (Control Center, Window Switcher, Window Killer, Monitor Manager, Wallpaper Gallery)
- Configuring Waybar, SwayNC, Wlogout, Walker, or SDDM themes

**If you are about to edit desktop UI, QML, Hyprland configs, or desktop scripts, STOP and review this skill first.**

---

## Topic Guides

Deep-dive instructions for each major desktop subsystem live next to this file. Read the matching guide before making changes:

- [`quickshell.md`](quickshell.md) - SicOS-Bar, QML architecture, Premium UX rules, Beaks/Vector mask, Wayland anchoring, focus management, overlays
- [`hyprland.md`](hyprland.md) - Hyprland configs, keybindings, window rules, multi-monitor setups, Kanshi persistence
- [`theming.md`](theming.md) - Stylix integration, Base16 schemes, `theme-switcher.sh`, wallpaper engine (`awww` / `sicos-wallpapers.py`)
- [`capture-tools.md`](capture-tools.md) - Region capture (`hyprshot` + `satty`), application launcher (`walker`), system controls (Caffeine, Night Mode, UPower)

---

## Critical Safety Rules

1. **Nix Store Immutability:**
   - NEVER try to write directly to `/nix/store/` or files symlinked into `/nix/store/`.
   - Modifying runtime files (like Kanshi configs) must target the repository source or bypass the Nix store (see `quickshell.md` and `hyprland.md`).

2. **Dual-Script Synchronization Rule:**
   - Many helper scripts exist in two locations:
     - Development/User-space: `home-manager/desktop/hyprland/scripts/<script>`
     - Module-space: `modules/sicos/hyprland/scripts/<script>`
   - Whenever you edit or fix a script in one of these directories, **you MUST update the other copy to keep them identical**.

3. **Zero CSS Borders in Beaked Popups:**
   - In QuickShell QML, `border.width` and `border.color` are strictly forbidden on interactive popups with pointer beaks to prevent ugly visual overlap with the vector mask. Always use the `OpacityMask` technique.

4. **Language Rule:**
   - All code, comments, user interface strings, buttons, tooltips, and labels must be written strictly in **English**.

5. **Existing Comments:**
   - Do not remove existing comments. Always explain *why* something is done, not just *what*. Place comments on the line immediately preceding the target code.

---

## System Architecture

| Component | Technology | Nix Configuration Location |
|---|---|---|
| **Compositor / WM** | Hyprland (Wayland) | `home-manager/desktop/hyprland/config/hyprland.conf` |
| **Desktop Shell** | QuickShell (QML / C++) | `modules/sicos/hyprland/config-files/quickshell/` |
| **Alternative Bars** | Waybar / DankMaterialShell | `modules/sicos/hyprland/config-files/waybar/` |
| **Global Theming** | Stylix + Base16 | `modules/sicos/hyprland/hm-module.nix` & `hosts/default.nix` |
| **Display Manager** | SDDM (Custom SicOS Theme) | `modules/sicos/hyprland/sddm-theme/` |
| **App Launcher** | Walker | Configured in `hm-module.nix` |
| **Notifications** | QuickShell OSD / SwayNC | `progressOsd.nix` or `config-files/swaync/` |
| **Session Menu** | Wlogout | `modules/sicos/hyprland/config-files/wlogout/` |
| **Wallpaper Daemon** | `awww` | Managed by `sicos-wallpapers.py` & `theme-switcher.sh` |
| **Display Layouts** | Kanshi + Hyprland IPC | `home-manager/desktop/hyprland/programs/kanshi/config` |

---

## Desktop Service Commands & Workflows

### Rebuilding Desktop Configuration
Apply system and desktop changes across flake hosts:
```bash
# Example for ironman host with hyprland:
sudo nixos-rebuild switch --flake .#<host>-hyprland
```

### Hot Reloading & Testing Components
- **Hyprland:** Auto-reloads on config save. Force reload:
  ```bash
  hyprctl reload
  ```
- **SicOS-Bar (QuickShell):**
  Restart QuickShell via UWSM to reload QML and pick up dynamic Nix changes:
  ```bash
  uwsm app -- quickshell &
  # or force kill and restart:
  pkill quickshell && uwsm app -- quickshell &
  ```
- **Theme Switching:**
  ```bash
  # Execute the master theme switcher
  ~/Zero/nixos-config/home-manager/desktop/hyprland/scripts/theme-switcher.sh
  ```

---

## Decision Framework

When handling a desktop customization or UI task:

1. **Is it a QuickShell bar/modal change?**
   - Follow [`quickshell.md`](quickshell.md).
   - Check if you need `WlrKeyboardFocus.OnDemand` or `Exclusive`.
   - Apply the *Focused-Screen Modal Pattern* if adding or modifying overlays.
   - Maintain Stylix color interpolation (`${c.base00}` to `${c.base0F}`).

2. **Is it a Hyprland keybind or window rule?**
   - Follow [`hyprland.md`](hyprland.md).
   - Inspect existing bindings using `show-hyprland-keybindings.sh`.
   - Validate syntax and run `hyprctl reload`.

3. **Is it a theme, color, or wallpaper change?**
   - Follow [`theming.md`](theming.md).
   - Edit `theming.mode` or `theming.base16Scheme` in `hosts/default.nix`.
   - Use `awww` or `sicos-wallpapers.py` for wallpaper management.

4. **Is it a monitor layout or scaling adjustment?**
   - Follow [`hyprland.md`](hyprland.md) (Monitors & Kanshi section).
   - Use `sicos-monitor-scale.sh` or `sicos-monitors.py` (`Super + K`).
