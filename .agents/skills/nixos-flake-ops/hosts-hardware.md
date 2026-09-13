# Hosts & Hardware Architecture Guide

Read this before editing host configurations, hardware drivers, or kernel parameters.

---

## Registered Hosts & Specifics

### 1. `strange` (Framework Laptop 13)
- **CPU/GPU:** AMD Ryzen AI 300 Series (Radeon 890M)
- **Nix Module:** Uses `nixos-hardware.nixosModules.framework-13-7040-amd`
- **Profiles:** `strange-hyprland`
- **Features:** Optimized power management and dynamic display scaling.

### 2. `rocket` (Custom Desktop PC)
- **CPU/GPU:** AMD CPU + Nvidia Dedicated GPU
- **Drivers:** Proprietary Nvidia drivers (`hardware.nvidia`), prime/offload or sync
- **Profiles:** `rocket-plasma`, `rocket-hyprland`, `rocket-cosmic`
- **Bootloader:** BIOS/MBR partitioning (`disko-config.nix` uses MBR layout).

### 3. `ironman` (Legacy Laptop)
- **CPU/GPU:** Intel Core i7 6700HQ + Nvidia GTX 960M
- **Kernel:** Specific kernel version (pinned to Linux 6.1 LTS for legacy hardware compatibility)
- **Profiles:** `ironman-plasma`, `ironman-hyprland`.

### 4. `taskmaster` (Work Laptop)
- **Profiles:** `taskmaster-plasma`, `taskmaster-hyprland`
- **Networking:** Fixed/static corporate IP configurations, work VPNs.

### 5. `vm` (Virtual Machine / Testing)
- **Environment:** QEMU/KVM
- **Desktop:** KDE Plasma (clean tinkering environment)
- **Guest Additions:** Spice guest agent enabled for auto-resize and clipboard sharing.
