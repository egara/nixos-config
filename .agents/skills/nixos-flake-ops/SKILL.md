---
name: nixos-flake-ops
description: >
  REQUIRED for system-level NixOS administration, Flake builds, host provisioning, Disko partitioning,
  or hardware configuration in this repository.
  Use when adding new hosts to hosts/, editing hardware-configuration.nix, disko-config.nix,
  rebuilding flake outputs, or debugging Nix build errors.
  Triggers: nixos-rebuild, flake.nix, hosts, disko, mkHost, hardware-configuration, systemPackages,
  garbage-collect, btrfs, partitioning, installer.
---

# NixOS Flake & System Operations Skill

Manage, build, and provision NixOS systems within this multi-host Flake repository.

## When This Skill MUST Be Used

**ALWAYS invoke this skill for requests involving ANY of these:**

- Adding or modifying machine configurations in `hosts/`
- Modifying `flake.nix` inputs or outputs
- Editing `disko-config.nix` or disk partitioning layouts
- Modifying `hardware-configuration.nix` or kernel parameters
- Adding system-wide packages or services in `configuration.nix`
- Executing system rebuilds (`nixos-rebuild switch`)
- Running system maintenance, rollbacks, or garbage collection (`nixos-clean.sh`)

---

## Topic Guides

- [`hosts-hardware.md`](hosts-hardware.md) - Machine profiles (`ironman`, `rocket`, `strange`, `taskmaster`, `vm`), hardware-specific quirks, kernel modules
- [`disko-partitioning.md`](disko-partitioning.md) - Disko BTRFS layout (`@`, `@home`, `@snapshots`), EFI, SWAP, automated install script

---

## Rebuild & Switch Workflows

Always specify the target host and profile flake output:

```bash
# General syntax:
sudo nixos-rebuild switch --flake .#<hostname>-<profile>

# Examples:
sudo nixos-rebuild switch --flake .#strange-hyprland
sudo nixos-rebuild switch --flake .#ironman-hyprland
sudo nixos-rebuild switch --flake .#rocket-hyprland
sudo nixos-rebuild switch --flake .#vm
```

### Dry Run & Build Testing:
Before switching on remote or sensitive machines, test the evaluation/build:
```bash
nixos-rebuild build --flake .#<hostname>-<profile>
```

---

## Adding a New Host

Follow this sequence to register a new machine:

1. **Create Host Folder:** `hosts/<hostname>/`
2. **Generate / Add Hardware Config:** `hardware-configuration.nix`
3. **Define Storage Layout:** `disko-config.nix` (standard UEFI/BTRFS or custom)
4. **Define Host Configuration:** `configuration.nix` (networking, hostname, specific packages)
5. **Register in `hosts/default.nix`:**
   Add an entry inside `in { ... }` using the `mkHost` function:
   ```nix
   "<hostname>-hyprland" = mkHost {
     hostname = "<hostname>";
     desktopProfile = "hyprland";
     themeMode = "dark";
     themeScheme = "catppuccin-mocha";
   };
   ```
