# Theming, Stylix & Wallpapers Guide

Read this before editing themes, color schemes, font configurations, wallpapers, or the theme switcher script.

---

## 1. Official Documentation & Palette References

- **Base16 Styling Architecture:** [https://github.com/chriskempson/base16/blob/main/styling.md](https://github.com/chriskempson/base16/blob/main/styling.md)
  (Outlines the exact semantic meaning of each slot `base00` to `base0F`).
- **Tinted Theming Scheme Gallery:** [https://tinted-theming.github.io/tinted-gallery/](https://tinted-theming.github.io/tinted-gallery/)
  (Visual preview of all standard Base16 color schemes).
- **Stylix Official Documentation:** [https://stylix.danth.me/](https://stylix.danth.me/)

---

## 2. Stylix & Base16 Global Theming

SicOS relies on [Stylix](https://github.com/danth/stylix) integrated in `modules/sicos/hyprland/hm-module.nix` for centralized color schemes, fonts, and cursors.

### Central Definition in `hosts/default.nix`
Theme mode, Base16 scheme, and font size are defined as local variables inside the `mkHost` function body in `hosts/default.nix` (shared by all hyprland hosts):
```nix
# Current values inside mkHost in hosts/default.nix
themeMode = "dark";                  # "dark" or "light"
themeScheme = "gruvbox-dark";        # Base16 scheme name
themeFontSize = 11;                  # Global Stylix font size
```
These variables are then applied to `programs.sicos.hyprland.theming.{mode,base16Scheme,fontSize}`.

### Base16 Color Map Reference
Stylix maps colors `c.base00` to `c.base0F`:
- `base00`: Default background (darkest in dark themes, lightest in light themes)
- `base01`: Lighter background (used for pills, cards, status bar background)
- `base02`: Selection background, interactive buttons
- `base03`: Borders, separators, button hover states
- `base04`: Muted text, subtitles, secondary indicators
- `base05`: Main foreground / text color
- `base06`: Light foreground (rarely used)
- `base07`: Brightest foreground
- `base08`: Red / Danger / Error (destructive actions, Caps Lock active, CPU critical)
- `base09`: Orange / Warning / Secondary accent
- `base0A`: Yellow / Warning (Num Lock active, warnings)
- `base0B`: Green / Success (active checks, power-saver profile, audio levels ok)
- `base0C`: Cyan / Alternative accent (screen sharing active)
- `base0D`: Blue / Primary Accent (active workspaces, sliders, balanced profile)
- `base0E`: Magenta / Purple
- `base0F`: Brown / Extra accent

---

## 3. Master Theme Switcher (`theme-switcher.sh`)

Location: `home-manager/desktop/hyprland/scripts/theme-switcher.sh`

### How It Works:
1. Prompts or accepts `--mode <light|dark>` and `--scheme <scheme>`.
2. Uses `sed` to update `themeMode` and `themeScheme` in `hosts/default.nix`.
3. Runs `sudo nixos-rebuild switch --flake .#<host>-hyprland`.
4. Hot-reloads running desktop services using `uwsm app`:
   - QuickShell / SicOS-Bar: restarted to pick up re-evaluated Stylix colors in QML.
   - Waybar, SwayNC, Walker: reloaded or restarted.
5. Updates wallpaper using `awww`.

---

## 4. Wallpaper Management Engine (`sicos-wallpapers.py` & `awww`)

SicOS uses `awww` as the Wayland wallpaper daemon.

### Wallpaper Directory
- Official and custom wallpapers live in `~/.config/sicos/wallpapers/` (including nested folders like `wallpaperdownloader/`).
- Repository default wallpapers: `modules/sicos/hyprland/wallpapers/`.

### CLI Engine (`sicos-wallpapers.py`):
```bash
# List all wallpapers with thumbnails
~/Zero/nixos-config/home-manager/desktop/hyprland/scripts/sicos-wallpapers.py --list

# Apply specific wallpaper with transition
~/Zero/nixos-config/home-manager/desktop/hyprland/scripts/sicos-wallpapers.py --set /path/to/img.png --resize crop

# Apply random wallpaper
~/Zero/nixos-config/home-manager/desktop/hyprland/scripts/sicos-wallpapers.py --random

# Generate / refresh thumbnail cache
~/Zero/nixos-config/home-manager/desktop/hyprland/scripts/sicos-wallpapers.py --gen-thumbs
```
The QuickShell Wallpaper Gallery (`wallpaper.nix`) directly connects to this script via `Quickshell.Io (Process)` to offer thumbnail grid browsing and filtering.
