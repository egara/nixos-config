# Hyprland Configuration & Display Management Guide

Read this before modifying Hyprland window rules, keybindings, animations, input devices, or monitor setups.

---

## 1. File Structure

```
home-manager/desktop/hyprland/
├── config/
│   ├── hyprland.conf            # Main Hyprland configuration (source of truth)
│   ├── hypridle.conf            # Idle daemon settings (dpms off, lock)
│   ├── hyprlock.conf            # Screen lock screen styling
│   └── satty.conf               # Screenshot annotation configuration
├── programs/
│   └── kanshi/
│       └── config               # Kanshi multi-monitor profile definitions
└── scripts/
    ├── sicos-monitors.py        # 2D monitor layout solver & Kanshi sync engine
    ├── sicos-monitor-scale.sh   # Live scaling helper invoked from Control Center
    └── show-hyprland-keybindings.sh
```

---

## 2. Keybindings Workflow

- **Check existing keybindings before adding or changing:**
  Inspect `home-manager/desktop/hyprland/config/hyprland.conf` or run:
  ```bash
  ~/Zero/nixos-config/home-manager/desktop/hyprland/scripts/show-hyprland-keybindings.sh
  ```
- **Common Default Bindings in SicOS:**
  - `Mod + Q`: Kill active window
  - `Mod + E`: Launch file manager (`nautilus`)
  - `Mod + F`: Toggle floating mode
  - `Mod + K`: Open Monitor Manager overlay (`toggle-monitormanager.sh`)
  - `Mod + S`: Open SicOS settings menu
  - `Mod + 1`: Random wallpaper switch
  - `Ctrl + Alt + T`: Launch terminal (`kitty`)
  - `Alt + Tab`: Open Window Switcher (`toggle-switcher.sh`)
  - `Mod + Arrow Keys`: Focus navigation
- **Testing & Reloading:**
  Hyprland monitors the config and reloads automatically on save. To force reload:
  ```bash
  hyprctl reload
  ```

---

## 3. Window Rules

> [!WARNING]
> Hyprland window rules syntax evolves across releases. Never guess the syntax. Always check existing patterns in `hyprland.conf` or the [official Hyprland window rules documentation](https://wiki.hypr.land/Configuring/Window-Rules/).

Common syntax patterns:
```ini
# Floating specific windows
windowrulev2 = float, class:^(org.gnome.Nautilus)$
windowrulev2 = size 900 600, class:^(org.gnome.Nautilus)$
windowrulev2 = center, class:^(org.gnome.Nautilus)$

# Picture-in-picture rules
windowrulev2 = float, title:^(Picture-in-Picture)$
windowrulev2 = pin, title:^(Picture-in-Picture)$

# QuickShell Layer Rules
layerrule = blur, quickshell:.*
layerrule = ignorezero, quickshell:.*
```

---

## 4. Multi-Monitor Setup & Kanshi Persistence

SicOS integrates dynamic runtime scaling and multi-monitor positioning with persistent declarative configs.

### Mechanics & Nix Store Bypass:
1. When Nix builds Home Manager, `~/.config/kanshi/config` defaults to a read-only symlink in `/nix/store/`.
2. `sicos-monitors.py` and `sicos-monitor-scale.py` execute `sync_local_kanshi_config()`:
   - Replaces the read-only Nix store symlink with a mutable symlink to `home-manager/desktop/hyprland/programs/kanshi/config`.
3. Changes made from the **Control Center Scale Pill** or **Monitor Manager (`Super+K`)** directly update the repository file and invoke:
   ```bash
   kanshictl reload
   ```
4. If Kanshi daemon is not active, fallback directly to Hyprland IPC:
   ```bash
   hyprctl keyword monitor "<output>,<resolution>,<position>,<scale>"
   ```

### Disambiguating Identical Displays:
`sicos-monitors.py` resolves connector IDs (`DP-1`, `DP-2`) with priority over monitor descriptions. This prevents multi-monitor profiles from confusing identical panels in multi-display setups.
