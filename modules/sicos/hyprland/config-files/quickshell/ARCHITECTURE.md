# SicOS-Bar (Quickshell) - Architecture, Design, and Knowledge Base

This document contains the "accumulated wisdom" of the SicOS-Bar project. When a new agent or developer joins the project, reading this document thoroughly will provide a perfect mental picture of how the bar works, how the Nix modules are structured, and what the design rules are to avoid chronic Wayland and QML bugs.

## 1. Goal of the SicOS-bar
A native and fully customized system bar (top panel) for the **SicOS** desktop environment, built purely in **QuickShell** (QML + Wayland). 
It offers a *Pill-style* interface (islands) with hyper-polished interactive modals ("Premium UX"), integrating perfectly into the NixOS ecosystem and changing colors dynamically with **Stylix**.

## 2. File Topology (The Nix + QML Ecosystem)
To avoid maintaining a monolithic `.qml` file with thousands of lines (which would destroy maintainability), the bar uses **Nix String Interpolation**. All QML code is housed within strings in Nix functions.

### Key NixOS & Home Manager Files
- **`modules/sicos/hyprland/default.nix`**: Defines the new `cfg.shell == "sicos-bar"` option. When selected, it adds the `quickshell` package to the system environment.
- **`modules/sicos/hyprland/hm-module.nix`**: Dynamically generates the configuration file `~/.config/quickshell/shell.qml`.
- **`home-manager/desktop/hyprland/scripts/theme-switcher.sh`**: Manages the light/dark theme change by restarting QuickShell (`uwsm app`) to apply the new Stylix colors instantly.

### Modular Components (Nix + QML)
- **`quickshell-bar.nix`:** The main skeleton (`Variants` over `Quickshell.screens` rendering a `PanelWindow` on each connected display). It defines the overall alignment (`RowLayout` with `AlignLeft`, `AlignCenter`, `AlignRight`). It injects the other modules by calling them like `${component}`.
- **`components/` (Base Directory):**
  - **`battery.nix`**: Advanced battery logic (`UPower`), remaining time calculation, 80% BIOS limit detection, and Popout Window animations.
  - **`wallpaper.nix`**: Wallpaper gallery popup and pill widget. Scans wallpapers from `~/.config/sicos/wallpapers` (including subfolders), displays thumbnail grid with active indicators, live search filtering, folder category chips, direct Nautilus folder opener, and middle-click random wallpaper trigger.
  - **`clock.nix`**: Real-time central clock (`Qt.formatDateTime`) and Calendar/Memento Mori modal.
  - **`misc.nix`**: Miscellaneous island hosting Keyboard lock indicators (Caps/Num Lock), real-time Pipewire privacy indicators (Microphone, Camera, Screen Sharing), the dynamic Power Profiles selector (`powerprofilesctl`), and the interactive MPRIS player.
  - **`controlcenter.nix`**: Centralized QuickShell Control Center hub containing user stats, network traffic telemetry, system volume/brightness sliders, and the **Monitor Scale Control Pill** (collapsible QML slider communicating with `sicos-monitor-scale.sh` for live and persistent scale management via Kanshi).
  - **`system.nix`**: App launcher button (`walker`) and system monitor (CPU/RAM ring charts).
  - **`workspaces.nix`**: Native two-way integration with Hyprland (`Quickshell.Hyprland`). Dynamically identifies open windows, rendering their system icons using a heuristic based on *class* and *title*.
  - **`windowswitcher.nix`**: Full-screen overlay modal for live window switching (`ALT+Tab`) using `ScreencopyView` and `WlrKeyboardFocus.OnDemand`.
  - **`windowkiller.nix`**: Full-screen overlay modal for visual force-killing of frozen/rogue applications (`SIGKILL` / `kill -9`) with skull tabs and live previews.
  - Component files are imported into `hm-module.nix` and passed as arguments to `quickshell-bar.nix`.
- **Theme Injection:** The main HM module reads colors from `config.lib.stylix.colors` and passes them (`c.base01`, `c.base05`, etc.) into the QML strings. There is no hardcoded CSS.

## 3. UI/UX Guidelines & Consistency (Style Guide)
To maintain a High-End look ("Premium UX"), all new elements must adhere to these guidelines:

- **Modal Headers:** All popup modals share a standardized header pattern:
  - Header Title: Clean typography `font.pixelSize: 18`, color `#${c.base05}`. Subtitle / stats count text: `font.pixelSize: 13`, color `#${c.base04}` (no square icon boxes in headers).
  - Header Action/Close Buttons: `width: 32; height: 32; radius: 16`, base color `"transparent"` or `#${c.base02}`, hovering to `#${c.base03}` (or `#${c.base08}` for destructive actions), aligned to the far right with `Item { Layout.fillWidth: true }`.
- **Modal Titles:** `font.pixelSize: 18`, **not** bold.
- **Subtitles/Sections:** Descriptive texts will use the accent color (`#${c.base0D}` Cyan), size `13`, centered horizontally (`Qt.AlignHCenter`).
- **Interactive Buttons:** Rounded design `radius: 20`, borderless. Base background `#${c.base02}`, changing to `#${c.base03}` on hover. Normal texts (only bold if representing an "active" state).
- **Lists and Rows:** List elements (`ListView` or repeaters) must use a `MouseArea` over the entire row to facilitate clicking (no tiny buttons). On hover, a slight highlight in `#${c.base03}` and display secondary action icons (e.g., delete button, which has the property `visible: mouseArea.containsMouse`).
- **Island Backgrounds (Pill background):** `#${c.base01}` inactive, `#${c.base03}` on hover, and `#${c.base02}` active/pressed.
- **Language Consistency:** All UI strings, labels, placeholders, empty states, tooltips, and code comments must strictly be written in English.
- **Transition Effects:** All modals must expand and hide using `Behavior on opacity` (200ms `OutCubic`) and `Behavior on y` (250ms `OutBack`) to give a spring or soft-drop sensation.

## 4. Advanced Engineering: The "Beaks" and Vector Mask
Modals in the SicOS-bar have a "comic bubble" style design (macOS control menu style), where a triangle (Beak) points to the clicked icon. So that the semi-transparent background (`#F0` - 94% opacity) does not reveal the dividing line (making the base square of the triangle visible):

- **Golden Rule:** **Zero CSS borders.** `border.width` and `border.color` are forbidden in interactive popups to avoid graphical overlaps.
- **`OpacityMask` Technique:**
  1. A `Rectangle` (`bgSource`) is created containing the pure background color.
  2. An `Item` (`bgMask`) is created geometrically containing the body (a rectangle with `16px` rounded corners) and the beak (a `20x20` rectangle rotated 45 degrees at `y: 2`).
  3. They are merged applying an `OpacityMask` over the visual origin. This makes the graphics engine process a single solid continuous figure that is transparency-proof.

## 5. Wayland Edge Clamping and "Breathing" Margin

### The Y "Breathing" Room of Modals
- So that the modal does not appear *stuck* to the toolbar, it needs to be pushed downwards invisibly.
- The main body of the modal (and the mask) must be defined with `anchors.topMargin: 12`. This leaves an invisible 12px top band where the tip of the beak protrudes.
- So that the internal elements of the modal (`ColumnLayout`) do not invade the top curve, their internal `topMargin` must be **32** (20 usual padding + 12 beak gap).
- *Clock Exception:* Since the clock modal anchors its "floor" to the central floating pill (which is separated from the global window background), it will begin mathematically painting 6 pixels higher. To equalize the visual "floor" of the other modals, the coordinates in `clock.nix` add +6px to their margins (`topMargin: 18`, `topMargin: 38`, `y: 8`).

### The Wayland Anchor Rules (Avoiding Violent Shifts)
The Wayland compositor (Hyprland in this case) uses strict rules for the LayerShell layer. If you define a very wide popup that tries to render centered on an icon near the edge of the screen, Wayland collides and *violently pushes* the modal towards the center of the screen to avoid cutting it (Edge Clamping). Since the modal was pushed but the beak calculation was relative to the button, the beak ends up pointing into thin air (e.g. over the workspaces buttons).

To avoid this, we use a hybrid popup anchoring system:
1. **Central Modals (Clock):** They are safe from the edge of the screen. They are allowed to use dynamic object-relative anchoring:
   ```qml
   anchor.item: clockWidgetContainer
   anchor.edges: Edges.Bottom
   anchor.gravity: Edges.Bottom
   ```
2. **Edge Modals (Sysinfo, Battery, Misc):** Never use `anchor.item`. We force Quickshell to firmly position the modal using the corners of the root window.
   - Battery/Misc: `anchor.rect.x: root.width - 10`, `anchor.edges: Edges.Bottom | Edges.Right`
   - SysInfo: `anchor.rect.x: 10`, `anchor.edges: Edges.Bottom | Edges.Left`
   - Since the modal is "frozen" and will never jump when pushed, the *Beak* is pushed individually and statically in the file (`anchors.leftMargin` or `rightMargin`) until its X falls mathematically on the visual center of the corresponding icon in the current bar layout.

## 6. Overlay Modals and Keyboard Focus Management

### The Window Switcher Pattern
The Window Switcher (`windowswitcher.nix`) is a full-screen overlay modal that displays live thumbnails of all open windows across all workspaces. It follows the same architectural patterns as the Workspace Overview but with a horizontal row layout instead of a grid.

**Key Implementation Details:**
- Uses `Variants` over `Quickshell.screens` but renders only on the focused screen (see the Focused-Screen Modal Pattern below).
- `WlrLayershell.layer: WlrLayer.Overlay` places it above all other windows.
- `WlrKeyboardFocus.OnDemand` is critical — see below.
- Communicates with Hyprland via a FIFO pipe (`/tmp/sicos-switcher-fifo`) since Quickshell cannot register global hotkeys directly.
- The Hyprland binding in `hyprland.lua` executes `toggle-switcher.sh`, which resolves the focused monitor and writes `toggle <monitor>\n` to the FIFO.
- A persistent `Process` with `SplitParser` in `quickshell-bar.nix` listens to the FIFO and toggles `windowSwitcherActive`.

### The Monitor Manager Pattern (Kanshi Integration)
The Monitor Manager (`monitormanager.nix`) provides dynamic screen enabling/disabling, 2D visual drag & drop positioning, resolution switching, and Kanshi profile synchronization invoked via `Super + K`:
- Uses `Variants` over `Quickshell.screens` with centered modal card (`radius: 28`), rendering only on the focused screen (see the Focused-Screen Modal Pattern below).
- Communicates via FIFO (`/tmp/sicos-monitors-fifo`) triggered by `toggle-monitormanager.sh`, which resolves the focused monitor and sends `toggle <monitor>\n` through the pipe.
- Integrates with `sicos-monitors.py` (`--status`, `--toggle <output>`, `--set <output> <enable|disable>`, `--set-mode <output> <mode>`, `--reorder <out1,out2,...>`, `--reorder-2d <out1:x:y,out2:x:y,...>`).
- **Interactive 2D Drag & Drop Placement:** Free-form visual arrangement canvas allowing users to arrange monitors horizontally, vertically stacked, or in multi-row/column matrices. Calculates accurate pixel offsets (`scale * resolution`) and guarantees zero overlapping.
- **Resolution Selector:** Dynamic dropdown displaying all hardware modes supported by Hyprland EDID, preselecting active mode and persisting changes to Kanshi.
- **Auto-profile Generation:** Automatically provisions and writes a default profile (`profile default-<hostname> { ... }`) if Kanshi is enabled without pre-existing or matched profiles.
- **Port ID & EDID Disambiguation:** Resolves physical connector IDs (`DP-1`, `DP-2`) with priority over descriptions, allowing identical monitor setups (e.g. dual office displays) to configure independently.
- **Direct Kanshi Persistence:** Directly updates `home-manager/desktop/hyprland/programs/kanshi/config` bypassing read-only `/nix/store` symlinks and invokes `kanshictl reload`.
- Gracefully displays a clean informative notice if Kanshi is disabled in the NixOS config.

### The Wallpaper Gallery Component
The Wallpaper Gallery (`wallpaper.nix`) is integrated into SicOS-Bar as an interactive popup modal providing fast wallpaper exploration, filtering, per-output targeting, and live switching via `awww`:
- **Backend Service (`sicos-wallpapers.py`):**
  - `--list`: Scans `~/.config/sicos/wallpapers` and subdirectories, queries active outputs and current wallpapers via `awww query`, and returns structured JSON with thumbnail cache locations.
  - `--set <path> [-o <output>] [-r <mode>]`: Dispatches wallpaper change via `awww img` with optional target output (`-o <output>` or all outputs) and resize method (`--resize <fit|crop|stretch|no>`).
  - `--random [-o <output>] [-r <mode>]`: Selects a random wallpaper from the collection and applies it to the selected display with chosen resize mode.
  - `--gen-thumbs`: Generates local cached square/16:9 thumbnail previews in `~/.cache/sicos-wallpaper-thumbs` for snappy UI scrolling.
- **Interactive UI Controls:**
  - **Outputs Dropdown:** Placed directly above the category pills. Automatically populates connected monitors (e.g. `eDP-1`, `DP-1`) alongside an `All Outputs` option.
  - **Resize Mode Dropdown:** Allows selecting between `fit`, `crop`, `stretch`, and `no` scaling methods.
  - **Folder Filter Chips:** Horizontal scrolling pills to filter wallpapers by subdirectory or show `All`.
  - **Active Wallpaper Badge:** Shows green checkmark badges on wallpaper cards matching the currently active wallpaper for the selected output (or across all outputs).
  - **Non-blocking Dropdown Overlays:** High z-index floating menus with outside-click dismiss and hover-close guards (`openDropdownIndex === -1`) to prevent unwanted modal closing while browsing options.

### The Focused-Screen Modal Pattern (Single-Screen Overlays)
Full-screen overlay modals instantiated through `Variants { model: Quickshell.screens }` are duplicated across every connected display. Unless a modal is explicitly meant to mirror on all screens, each overlay window must gate its own visibility so that **only the screen from which the modal was invoked renders it**. This is implemented by the Workspace Overview (`overview.nix`), Window Switcher (`windowswitcher.nix`), Window Killer (`windowkiller.nix`) and Monitor Manager (`monitormanager.nix`).

**Golden rule:** the target-screen check must also gate the fade-out clause. A naive `visible: modalActive && targetMatches || (modalCard.opacity > 0)` is wrong: while the modal is open, `modalCard.opacity` is `1` on every screen, so the fade-out clause re-enables visibility everywhere and the modal mirrors again. The correct form is `visible: targetMatches && (modalActive || modalCard.opacity > 0)`.

**Checklist for any new overlay modal:**
1. Declare a target property in `quickshell-bar.nix` next to its `*Active` flag:
   ```qml
   property bool myModalActive: false
   property string myModalTargetScreen: ""
   ```
2. In the component's `PanelWindow`, declare the target check and use it for visibility:
   ```qml
   property bool isTargetScreen: myModalTargetScreen === "" || modelData.name === myModalTargetScreen
   visible: isTargetScreen && (myModalActive || modalCard.opacity > 0)
   ```
3. Feed the target depending on the trigger type:
   - **Hyprland keybind via FIFO script** (Monitor Manager, Window Switcher): the toggle script resolves the focused monitor and sends it through the pipe:
     ```bash
     FOCUSED=$(hyprctl -j monitors 2>/dev/null | jq -r '.[] | select(.focused == true) | .name')
     (printf 'toggle %s\n' "$FOCUSED" > "$FIFO") &
     ```
     The FIFO listener in `quickshell-bar.nix` parses `toggle <monitor>` and only assigns the target when opening. A bare `toggle` (empty target) falls back to rendering on every screen. Remember to keep both copies of the script in sync (`modules/sicos/hyprland/scripts/` and `home-manager/desktop/hyprland/scripts/`).
   - **Bar button** (Workspace Overview, Window Killer): the button lives inside the per-screen bar `PanelWindow` (`id: root`), so it sets the target directly before opening:
     ```qml
     myModalTargetScreen = root.screen.name;
     myModalActive = true;
     ```
4. Closing (`*Active = false`) needs no target handling: the fade-out clause keeps the target screen mapped until `modalCard.opacity` reaches `0`, and non-target screens are never mapped at all.

### Keyboard Focus: OnDemand vs Exclusive
When building overlay modals that need to **transfer focus to other windows** (like a window switcher), the keyboard focus mode is critical:

- **`WlrKeyboardFocus.Exclusive`**: Blocks all other applications from receiving keyboard focus. This is ideal for modals that are purely informational (like the Calendar or System Monitor). However, **it prevents Hyprland from transferring focus to other windows** while the overlay is visible. If you try to dispatch `focuswindow` while an Exclusive overlay is open, Hyprland may move the cursor but cannot change the keyboard focus.

- **`WlrKeyboardFocus.OnDemand`**: The overlay receives keyboard input when the user interacts with it, but **does not block** the compositor from focusing other windows. This is essential for interactive overlays like the Window Switcher, where selecting a window must immediately transfer focus to it.

**Golden Rule:**
- Use `Exclusive` for modals that are "read-only" or "self-contained" (Calendar, System Info, Battery).
- Use `OnDemand` for modals that need to **act on other windows** (Window Switcher, any future window management UI).

## 7. References & Documentation
- **Official Quickshell Documentation (v0.1.0):** [https://quickshell.org/docs/v0.1.0/guide/](https://quickshell.org/docs/v0.1.0/guide/)
- **Local Reference Projects (Source Code):**
  - **DankMaterialShell (DMS):** `/home/egarcia/Development/git/DankMaterialShell`
  - **Omarchy:** `/home/egarcia/Development/git/omarchy`
  - *(Note for agents: When requested to review or copy functionalities from these projects, you must thoroughly investigate the source code in these directories).*
