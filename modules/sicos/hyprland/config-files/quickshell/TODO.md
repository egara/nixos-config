# SicOS-Bar (Quickshell) - Pending Tasks & Roadmap

This document details the modules and features that are still pending development for the SicOS-bar.

## Planned Modules

1. **Dedicated Network Modal:**
   - A modal dedicated exclusively to viewing and managing network connections.
   - Visual scanning of available Wi-Fi networks, display of network status (connected/disconnected), and IP address.

2. **Caffeine Mechanism (Screen Saver Inhibitor):**
   - Interactive toggle button in the bar (possibly in the `misc` island).
   - Purpose: Prevent the system from sleeping or turning off the screen when the user needs it to stay active.
   - Technical logic: Interact with the `hypridle` process (temporarily killing the daemon or using a standard Wayland session inhibitor) and reactivate it on demand.

3. **Master Control Center Modal:**
   - A large, unified modal (similar to macOS Control Center) grouping:
     - **Hardware Sliders:** Manual and visual management of audio volume and screen brightness.
     - **Quick Toggles (Quick action buttons):**
       - Enable/Disable Bluetooth.
       - Enable/Disable Wi-Fi Network.
       - Airplane Mode.
     - **Session Management:** Additional controls to suspend, restart, log out, and shut down the system (with visual confirmations if necessary).

4. **Expanded Multimedia Control (MPRIS):**
   - Polish controls and visualizations of the active player in future iterations if necessary.
