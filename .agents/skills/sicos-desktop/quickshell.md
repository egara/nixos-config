# SicOS-Bar (QuickShell) Architecture & Development Guide

Read this before modifying or creating any QuickShell QML component in `modules/sicos/hyprland/config-files/quickshell/`.

QuickShell provides a native C++/QML Wayland layer-shell panel (`sicos-bar`). Rather than a monolithic `.qml` file, the bar is split into modular Nix expressions (`components/*.nix`) interpolated into QML within `quickshell-bar.nix`.

```
modules/sicos/hyprland/config-files/quickshell/
├── quickshell-bar.nix               # Main bar skeleton, Screen variants & popups
├── components/
│   ├── battery.nix                  # Battery status (UPower) & power warnings
│   ├── clock.nix                    # Center clock & Memento Mori calendar modal
│   ├── controlcenter.nix            # Sliders, network stats, scaling pill, toggles
│   ├── misc.nix                     # Caps/Num lock, Pipewire privacy badges, MPRIS
│   ├── monitormanager.nix           # Super+K visual 2D display manager overlay
│   ├── overview.nix                 # Workspace overview overlay
│   ├── progressOsd.nix              # Floating top pill alerts (Vol/Bright/Locks)
│   ├── targetosd.nix                # Shared per-screen target feedback OSD (wallpaper output, scale)
│   ├── system.nix                   # CPU/RAM Canvas charts & Walker launcher
│   ├── wallpaper.nix                # Wallpaper gallery modal & Nautilus trigger
│   ├── windowkiller.nix             # Kill -9 frozen window visual overlay
│   ├── windowswitcher.nix           # Alt+Tab ScreencopyView live thumbnails
│   └── workspaces.nix               # Hyprland workspaces & app title/class heuristics
```

---

## 1. Official Documentation & Local References

> [!CRITICAL]
> **DO NOT GUESS QUICKSHELL OR WAYLAND LAYERSHELL APIS.**
> QuickShell types (`Variants`, `PanelWindow`, `WlrKeyboardFocus`, `Quickshell.Hyprland`, `Quickshell.Services.*`) have unique semantics that differ from standard QtQuick.
> Whenever unsure about an API property, syntax, or method, consult the official documentation or local reference implementations before writing code:
> - **Official QuickShell Docs:** [https://quickshell.org/docs/v0.1.0/guide/](https://quickshell.org/docs/v0.1.0/guide/)
> - **Local Reference Implementations (Inspection Safe):**
>   - DankMaterialShell: `/home/egarcia/Development/git/DankMaterialShell`
>   - Omarchy: `/home/egarcia/Development/git/omarchy`

---

## 2. Nix String Interpolation & Stylix Injection

QML files are written as strings inside Nix functions. Stylix theme colors and fonts are passed dynamically:

- Colors: `#${c.base00}` through `#${c.base0F}`
- Fonts: `${fontName}` (JetBrainsMono Nerd Font)
- **Zero hardcoded hex colors:** Always use `${c.base0X}` for styling.

Example component structure:
```nix
{ config, pkgs, ... }:
let
  # helper expressions or imports
in
''
  // Pure QML starts here
  Item {
    // ...
  }
''
```

---

## 3. UI/UX Style Guide ("Premium UX")

- **Modal Headers:** Clean typography `font.pixelSize: 18`, color `#${c.base05}`. Subtitles / counters: `font.pixelSize: 13`, color `#${c.base04}` (never use square icon boxes in headers).
- **Close/Action Buttons:** `width: 32; height: 32; radius: 16`, base color `"transparent"` or `#${c.base02}`, hovering to `#${c.base03}` (or `#${c.base08}` for destructive actions).
- **Subtitles/Sections:** Accent color `#${c.base0D}` (Cyan/Blue), size 13, centered horizontally (`Qt.AlignHCenter`).
- **Interactive Buttons:** `radius: 20`, borderless. Base background `#${c.base02}`, hover `#${c.base03}`.
- **Island Indicator Badges (`misc.nix`):**
  - All status items inside the Misc island must follow the uniform **24x24 circular badge pattern**:
    `width: 24; height: 24; radius: 12`
  - Text: `anchors.centerIn: parent`, font size 13-16px, color `#${c.base00}` for active states.
  - Active color semantics:
    - `#${c.base08}` (Red): Caps Lock, Active Unmuted Mic, Performance Profile
    - `#${c.base09}` (Orange): Active Camera in use
    - `#${c.base0A}` (Yellow): Num Lock
    - `#${c.base0B}` (Green): Power-saver Profile
    - `#${c.base0C}` (Teal): Screen Sharing in use
    - `#${c.base0D}` (Blue): Active MPRIS Playing, Balanced Profile
  - Inactive/Muted: `#${c.base02}` or `#${c.base03}` background.

---

## 4. Advanced Engineering: Beaks and Vector Masks

Popups feature an iOS/macOS-style pointer beak (triangle).

- **CRITICAL RULE: ZERO CSS BORDERS.** Never use `border.width` or `border.color` on popup bodies with beaks, as it creates visible seams across semi-transparent backgrounds (`#F0` opacity).
- **OpacityMask Technique:**
  1. `bgSource`: Solid `Rectangle` with popup color.
  2. `bgMask`: `Item` containing both the body (`Rectangle` with `radius: 16`) and the beak (`Rectangle { width: 20; height: 20; rotation: 45 }`).
  3. Merge with `OpacityMask` over the background.

---

## 5. Wayland LayerShell Anchoring & Edge Clamping

Hyprland pushes LayerShell popups if they overflow the screen edge ("Edge Clamping"), misaligning beaks if dynamically anchored to buttons near borders.

- **Center Modals (Clock):** Safe from screen borders; use dynamic object-relative anchoring:
  ```qml
  anchor.item: clockWidgetContainer
  anchor.edges: Edges.Bottom
  anchor.gravity: Edges.Bottom
  ```
- **Edge Modals (SysInfo, Battery, Misc, Control Center):**
  - Anchor firmly to root window corners instead of `anchor.item`:
    - Right popups: `anchor.rect.x: root.width - 10`, `anchor.edges: Edges.Bottom | Edges.Right`
    - Left popups: `anchor.rect.x: 10`, `anchor.edges: Edges.Bottom | Edges.Left`
  - Position the beak independently using `anchors.leftMargin` or `rightMargin` to point exactly at the visual center of the widget button.
- **Top Y "Breathing" Margin:**
  - Body and mask use `anchors.topMargin: 12` so the beak tip protrudes above the card.
  - Content containers use `topMargin: 32` (20 padding + 12 beak gap).

---

## 6. Overlay Modals & Keyboard Focus

### Focused-Screen Modal Pattern (Single-Screen Overlays)
Overlays in `Variants { model: Quickshell.screens }` render on every monitor unless gated.
**Golden Rule:** The target screen check must gate both active visibility AND fade-out animations:
```qml
// CORRECT:
property bool isTargetScreen: myModalTargetScreen === "" || modelData.name === myModalTargetScreen
visible: isTargetScreen && (myModalActive || modalCard.opacity > 0)

// WRONG (will cause mirrors on other screens during fade-out):
visible: myModalActive && targetMatches || (modalCard.opacity > 0)
```

### Keyboard Focus: OnDemand vs Exclusive
- **`WlrKeyboardFocus.Exclusive`**: Use ONLY for read-only modals (Calendar, System Specs). **Blocks Hyprland from dispatching focus to other windows.**
- **`WlrKeyboardFocus.OnDemand`**: MANDATORY for interactive window pickers (Window Switcher, Window Killer) that need to pass focus to target windows upon selection.

---

## 7. IPC Pipes & Script Triggers

QuickShell communicates with Hyprland global shortcuts via FIFO pipes in `/tmp/`:
- Window Switcher: `/tmp/sicos-switcher-fifo` (triggered by `toggle-switcher.sh` via `Alt+Tab`)
- Monitor Manager: `/tmp/sicos-monitors-fifo` (triggered by `toggle-monitormanager.sh` via `Super+K`)

Processes in `quickshell-bar.nix` use `Process` with `SplitParser` to listen and update properties.

## 8. Target OSD Pattern (Multi-Monitor Feedback)

Any UI action that **targets a specific output** (wallpaper output dropdown, monitor scale pill, and future per-monitor settings) must give the user visual feedback **on the affected screen**, identifying it. Use the shared component, never a bespoke popup:

- **Component:** `targetosd.nix`, interpolated as `${targetOsd.widget}` *inside* the per-screen bar `PanelWindow` of the `Variants` block (one instance per monitor). Top-center volume-style pill (`margins { top: 60 }`, `radius: 28`, accent `#${c.base0D}`, `WlrLayer.Overlay`).
- **API (global in `quickshell-bar.nix`):**
  ```qml
  mainScope.showTargetOsd(outputs, label, value)
  ```
  - `outputs`: array of output names (e.g. `["DP-1"]`, or all outputs for "All Outputs").
  - `label`: context of the action; defaults to `"Output"`.
  - `value`: right-hand text; when empty each OSD falls back to the name of the screen it is rendered on (each monitor identifies itself).
  - Auto-hides after 2s via `targetOsdTimer` (re-calling extends the timeout).
- **Visibility gating:** each instance checks `mainScope.targetOsdOutputs.indexOf(root.screen.name) !== -1`. Output names from backends (`hyprctl monitors -j`) match QuickShell `screen.name`, so the check is a plain string comparison.
- **Current consumers:**
  - Wallpaper Gallery (`wallpaper.nix`): output dropdown shows `Output | DP-1` on that screen; `All Outputs` fires one OSD per monitor.
  - Control Center (`controlcenter.nix`): monitor switch or scale apply (`-`/`+`/slider release via `setMonitorScale()`) shows `Scale | DP-1 · 1.25x` on the affected screen.

**Golden rule:** every new multi-monitor setting must trigger the shared Target OSD instead of inventing a new feedback UI, keeping geometry, animation, and styling consistent with the "Premium UX" language.
