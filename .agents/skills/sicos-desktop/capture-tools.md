# Capture, Launcher & System Controls Guide

Read this before modifying screenshot workflows, screen recording, application launcher scripts, or desktop quick toggles.

---

## 1. Screenshots & Annotations

SicOS uses `hyprshot` combined with `satty` for an interactive snapshot flow.

- **Trigger:**
  - Control Center snapshot icon or dedicated keybinding.
- **Workflow:**
  1. `hyprshot -m region --raw`: Captures selected screen rectangle.
  2. Piped into `satty --filename - --fullscreen --output-filename ~/Pictures/Screenshots/screenshot-%Y%m%d-%H%M%S.png`.
  3. `satty` allows drawing arrows, boxes, text, blurring sensitive information, and copying directly to the clipboard or saving to disk.
- **Configuration:** Passed inline via command-line flags when `satty` is invoked (no `satty.conf` file exists).

---

## 2. Application Launcher & Menus (Walker)

[Walker](https://github.com/abenz1267/walker) acts as the high-performance application launcher, runner, and dmenu replacement in SicOS.

- **Trigger:** `Super` or click on the launcher button in SicOS-Bar.
- **Keybindings Cheatsheet:**
  The script `home-manager/desktop/hyprland/scripts/show-hyprland-keybindings.sh` reads live keybindings via `hyprctl binds -j` (Hyprland IPC) and opens an interactive, searchable Walker menu.
- **Configured via:** `modules/sicos/hyprland/hm-module.nix`.

---

## 3. Quick Toggles & Power Management

Located in the **Control Center (`controlcenter.nix`)** and **Misc Island (`misc.nix`)**:

### Caffeine (Idle Inhibitor)
- Controls `hypridle`.
- Helper: `toggle-hypridle.sh`.
- When ON: Inactive screensaver/sleep lock.
- When OFF: Normal timeout rules in `hypridle.conf` apply.
- Displays state toggle via floating OSD (`progressOsd.nix`).

### Night Mode (Blue Light Filter)
- Controls `hyprsunset`.
- Helper: `toggle-nightlight.sh`.
- Applies color temperature (e.g. 4000K) or resets to 6500K.

### Power Profiles (`powerprofilesctl`)
- Integrated into SicOS-Bar Misc island and `power-management.nix`.
- Profiles: `performance` (Red badge), `balanced` (Blue badge), `power-saver` (Green badge).
- Automatic switching on AC connect/disconnect for laptops.
