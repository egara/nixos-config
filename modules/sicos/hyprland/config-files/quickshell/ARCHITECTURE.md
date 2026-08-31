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
- **`quickshell-bar.nix`:** The main skeleton (`PanelWindow`). It defines the overall alignment (`RowLayout` with `AlignLeft`, `AlignCenter`, `AlignRight`). It injects the other modules by calling them like `${component}`.
- **`components/` (Base Directory):**
  - **`battery.nix`**: Advanced battery logic (`UPower`), remaining time calculation, 80% BIOS limit detection, and Popout Window animations.
  - **`clock.nix`**: Real-time central clock (`Qt.formatDateTime`) and Calendar/Memento Mori modal.
  - **`misc.nix`**: Miscellaneous island hosting the dynamic Power Profiles selector, session buttons (`powerprofilesctl`), and the interactive MPRIS player.
  - **`system.nix`**: App launcher button (`walker`) and system monitor (CPU/RAM ring charts).
  - **`workspaces.nix`**: Native two-way integration with Hyprland (`Quickshell.Hyprland`). Dynamically identifies open windows, rendering their system icons using a heuristic based on *class* and *title*.
  - Component files are imported into `hm-module.nix` and passed as arguments to `quickshell-bar.nix`.
- **Theme Injection:** The main HM module reads colors from `config.lib.stylix.colors` and passes them (`c.base01`, `c.base05`, etc.) into the QML strings. There is no hardcoded CSS.

## 3. UI/UX Guidelines & Consistency (Style Guide)
To maintain a High-End look ("Premium UX"), all new elements must adhere to these guidelines:

- **Modal Titles:** `font.pixelSize: 18`, **not** bold.
- **Subtitles/Sections:** Descriptive texts will use the accent color (`#${c.base0D}` Cyan), size `13`, centered horizontally (`Qt.AlignHCenter`).
- **Interactive Buttons:** Rounded design `radius: 20`, borderless. Base background `#${c.base02}`, changing to `#${c.base03}` on hover. Normal texts (only bold if representing an "active" state).
- **Lists and Rows:** List elements (`ListView` or repeaters) must use a `MouseArea` over the entire row to facilitate clicking (no tiny buttons). On hover, a slight highlight in `#${c.base03}` and display secondary action icons (e.g., delete button, which has the property `visible: mouseArea.containsMouse`).
- **Island Backgrounds (Pill background):** `#${c.base01}` inactive, `#${c.base03}` on hover, and `#${c.base02}` active/pressed.
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

## 6. References & Documentation
- **Official Quickshell Documentation (v0.1.0):** [https://quickshell.org/docs/v0.1.0/guide/](https://quickshell.org/docs/v0.1.0/guide/)
- **Local Reference Projects (Source Code):**
  - **DankMaterialShell (DMS):** `/home/egarcia/Development/git/DankMaterialShell`
  - **Omarchy:** `/home/egarcia/Development/git/omarchy`
  - *(Note for agents: When requested to review or copy functionalities from these projects, you must thoroughly investigate the source code in these directories).*
