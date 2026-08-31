# SicOS-Bar (Quickshell) - Completed Modules

This document contains a historical record of all features, modules, and integrations that have already been developed and stabilized for the SicOS bar.

## System Core & Architecture
- **Setup and Modular Architecture:** Refactoring completed via Nix interpolation (`quickshell-bar.nix` injecting files in `components/`), ensuring scalability and incredibly clean QML code.
- **Base Layout (QML):** Floating pill-style design, transparent, correctly anchored to the graphical environment.
- **Dynamic Theming:** Full integration with **Stylix** (instant light/dark switching via reload triggered by `uwsm app`).

## Developed Modules

### 1. Clock and Calendar (Premium UX)
- Interactive, natively centered central clock avoiding Wayland *Edge Clamping* issues.
- Split-panel modal: Calendar (navigable months) and *Memento Mori* (life expectancy progress bar).
- Correct Wayland keyboard focus management (`HyprlandFocusGrab` + `WlrLayershell.keyboardFocus`).

### 2. Notifications
- Integration of Quickshell's notification API.
- History grouped by applications inside the clock island.
- Dynamic floating OSD popups with fluid animations, icon rendering, and support for click actions (dismiss or invoke).

### 3. Workspaces
- Bidirectional integration with Hyprland (`Quickshell.Hyprland`).
- Dynamic rendering of pills per workspace.
- Heuristic system to identify app icons, including advanced mapping for TUI terminal applications (btop, yazi, neovim) by reading window titles.

### 4. Multimedia Module (MPRIS)
- Modern visual player, extraction of track cover art with blurred *FastBlur* effect as the island's background.
- Fully functional progress bar (Interactive Slider) anchored to `activePlayer.position`.
- Foundational architecture of the "Beak" using a borderless Vector Opacity Mask (`OpacityMask`) for an Apple-style design.

### 5. Power Management and Battery
- **Power Profiles:** Persistent performance selector in the Misc island.
- **Advanced Battery:** Predictive calculation (Time remaining, Capacity, Health) from `UPower`.
- Interactive modal anchored to the right, with support for an intelligent 80% warning (hardware charge limit on laptops).

### 6. System Monitor (CPU/RAM)
- Real-time system reading in the bar.
- Informative modal firmly anchored to the left edge.
- Top 5 resource-consuming processes lists (Hidden dynamic button on hover to kill the process).
- Circular ring charts drawn using `Canvas`.

### 7. System Tray
- Integration with `Quickshell.Services.SystemTray`.
- Native mouse interactions supporting all external providers (NetworkManager, Bluetooth, Insync, etc.).
