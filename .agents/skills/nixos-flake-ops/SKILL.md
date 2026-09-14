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

## 1. Official Documentation & Package / Option Search

> [!CRITICAL]
> **VERIFY NIXOS AND HOME MANAGER OPTIONS BEFORE IMPLEMENTING.**
> Options in `nixpkgs-unstable` and `home-manager` evolve across channel updates. If configuring a new system service, bootloader parameter, or package configuration, use the official search engines:
> - **NixOS Options Search:** [https://search.nixos.org/options](https://search.nixos.org/options)
> - **Nix Packages Search:** [https://search.nixos.org/packages](https://search.nixos.org/packages)
> - **Home Manager Options:** [https://home-manager-options.extranix.com/](https://home-manager-options.extranix.com/)
> - **Disko Repository & Examples:** [https://github.com/nix-community/disko](https://github.com/nix-community/disko)
> - **NixOS Hardware Quirks:** [https://github.com/NixOS/nixos-hardware](https://github.com/NixOS/nixos-hardware)

---

## 2. When This Skill MUST Be Used

**ALWAYS invoke this skill for requests involving ANY of these:**

- Adding or modifying machine configurations in `hosts/`
- Modifying `flake.nix` inputs or outputs
- Editing `disko-config.nix` or disk partitioning layouts
- Modifying `hardware-configuration.nix` or kernel parameters
- Adding system-wide packages or services in `configuration.nix`
- Executing system rebuilds (`nixos-rebuild switch`)
- Running system maintenance, rollbacks, or garbage collection (`home-manager/desktop/hyprland/scripts/nixos-clean.sh`)

---

## 3. Topic Guides

- [`hosts-hardware.md`](hosts-hardware.md) - Machine profiles (`ironman`, `rocket`, `strange`, `taskmaster`, `vm`), hardware-specific quirks, kernel modules
- [`disko-partitioning.md`](disko-partitioning.md) - Disko BTRFS layout (`@`, `@home`, `@snapshots`), EFI, SWAP, automated install script

---

## 4. Rebuild & Switch Workflows

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

## 5. Adding a New Host

Follow this sequence to register a new machine:

1. **Create Host Folder:** `hosts/<hostname>/`
2. **Generate / Add Hardware Config:** `hardware-configuration.nix`
3. **Define Storage Layout:** `disko-config.nix` (standard UEFI/BTRFS or custom)
4. **Define Host Configuration:** `configuration.nix` (networking, hostname, specific packages)
5. **Define the host module list in `hosts/default.nix`** (before the `in` block), following the existing `<hostname>Modules` pattern:
   ```nix
   # Modules for <hostname>
   <hostname>Modules = [
     disko.nixosModules.disko
     {
       _module.args.disks = [ "/dev/nvme0n1" ];
       imports = [ (import ./<hostname>/disko-config.nix) ];
     }
     ./<hostname>/hardware-configuration.nix
     ./efi-configuration.nix          # or ./bios-configuration.nix
     ./<hostname>/configuration.nix
   ];
   ```
6. **Register in `hosts/default.nix`:**
   Add an entry inside `in { ... }` using the `mkHost` function:
   ```nix
   "<hostname>-hyprland" = mkHost {
     hostName = "<hostname>";
     desktop = "hyprland";            # "plasma", "hyprland" or "cosmic"
     extraModules = <hostname>Modules;
     # homeManagerExtraImports = [ ... ];  # optional
   };
   ```

> [!NOTE]
> **Theming is NOT a `mkHost` argument.** `themeMode`, `themeScheme`, and `themeFontSize` are local variables defined inside the `mkHost` function body in `hosts/default.nix` (applied to `programs.sicos.hyprland.theming.*`). To change the theme for all hyprland hosts, edit those local variables there.
