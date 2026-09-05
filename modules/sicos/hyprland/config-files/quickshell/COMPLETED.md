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

### 8. Control Center
- Centralized action hub accessible via a dedicated sliders icon on the bar.
- **User Profile Header:** Dynamic, expandable header displaying the user avatar, username, and host. Clicking expands the section to reveal system Uptime, OS details, and Omarchy-style real-time Network Statistics (Ping, Packet Loss, current Rx/Tx speeds, and total downloaded data), all fetched via an internal background polling mechanism.
- **Toggles & Services:** Integrated bottom row featuring Caffeine (controlling `hypridle` for screensaver/sleep) and Night Mode (controlling `hyprsunset` for color temperature), complete with visual active states and custom stylized notifications.
- **System Information:** Dedicated "Info" action button that spawns a perfectly centered, floating terminal window running `fastfetch` for instant system specs.
- **Snapshot Utility:** Dedicated "Camera" action button that closes the control center and triggers `hyprshot` with `satty` for on-the-fly region screenshotting and annotation.
- **Keybindings Cheatsheet:** Dedicated "Keybindings" action button that invokes a clean, read-only `walker` menu containing an automatically parsed list of all active Hyprland keybindings (`show-hyprland-keybindings.sh`).
- **Power Menu:** Quick access to the system shutdown/reboot menu via `wlogout`.
- **Monitor Scaling Pill:** Collapsible monitor scaling module inside the Control Center. Displays a stylized Nerdfont monitor icon (`󰍹`), current monitor name, and scale. Expanding reveals step buttons (`-`/`+`) and a continuous slider to dynamically adjust resolution scaling. Integrates with `sicos-monitor-scale.sh` to update scale in real-time and persist changes to Kanshi configurations (`home-manager/desktop/hyprland/programs/kanshi/config`) while bypassing `/nix/store` read-only symlinks.

### 9. Audio & Brightness Controls
- **Volume Management:** Real-time volume slider integration via Quickshell's internal services. Mute toggle on interaction and dynamic icon updating (speaker waves) based on the volume percentage.
- **Brightness Management:** Dynamic brightness slider adjusting screen backlight (`brillo`/`brightnessctl`), coupled with real-time UI synchronization and proper icon updates (sun with varying rays).

### 10. Network & Connectivity
- **Real-time Network Statistics:** Real-time upload and download speed metrics dynamically displayed, scaled in Kbps/Mbps.
- **Visual State Indicators:** Active interface icons updating based on connectivity status (WiFi signal strength icons, Ethernet wired icon, or disconnected state), fully integrated into the system tray area.

### 11. Window Switcher (Alt + Tab Overlay)
- **Visual Window Switcher:** A full-screen overlay triggered by `ALT + Tab` showing live thumbnails of **all windows across all workspaces and monitors**.
- **Live Previews:** Each window card renders a real-time clone via `ScreencopyView` with `scaleToFit` scaling, centered in the card while maintaining aspect ratio.
- **Keyboard Navigation:** `Left`/`Right` arrow keys or `Tab`/`Shift+Tab` cycle the selection. `Enter` confirms and focuses the selected window. `Escape` dismisses the switcher without changing focus.
- **Mouse Interaction:** Hover highlights a card, click focuses the window and closes the switcher. Clicking outside the modal dismisses it.
- **Auto-selection:** The currently focused window is automatically selected when the switcher opens.
- **Hyprland Integration:** Communicates with Hyprland via a FIFO pipe (`/tmp/sicos-switcher-fifo`), triggered by the `toggle-switcher.sh` script bound to `ALT + Tab` in `hyprland.lua`.
- **Keyboard Focus Strategy:** Uses `WlrKeyboardFocus.OnDemand` (not `Exclusive`) so that the overlay can receive keyboard input while still allowing Hyprland to transfer focus to other windows when a selection is made.
- **Consistent Theming:** Uses the same Stylix color palette, animations (`OutBack`/`OutCubic`), and border-radius patterns as the Workspace Overview and other Premium UX modals.
