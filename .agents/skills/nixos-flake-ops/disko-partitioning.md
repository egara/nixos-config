# Disko Partitioning & Automated Installation Guide

Read this before modifying disk layouts, filesystems, or the automated installer script.

---

## 1. Disko BTRFS Layout Standard

All modern UEFI machines in this repository (`strange`, `ironman`, `taskmaster`, `vm`) use Disko with BTRFS subvolumes:

```
(Disk Volume)
├── /boot/efi       FAT32 (512 MiB, Bootable/ESP)
├── [SWAP]          Swap Partition (4 GiB - 32 GiB depending on RAM)
└── / (BTRFS)       Label: 'system'
    ├── @           Subvolume mounted at /
    ├── @home       Subvolume mounted at /home
    └── @snapshots  Subvolume mounted at /.snapshots
```

*Note on Rocket:* `rocket` uses an MBR/BIOS layout with `ext4` due to legacy hardware constraints.

---

## 2. Automated Installation Script (`scripts/install.sh`)

Bootstrap a machine from a NixOS Minimal Live USB:

```bash
curl -sL https://raw.githubusercontent.com/egara/nixos-config/main/scripts/install.sh | bash -s <host> <profile> <username>
```

### Accepted Parameters:
- **`host`**: `vm`, `rocket`, `ironman`, `taskmaster`, `strange`
- **`profile`**: `<host>-hyprland`, `<host>-plasma`, `<host>-cosmic`
- **`username`**: default is `egarcia`

### What the installer does:
1. Clones the repository to `/tmp/nixos-config`
2. Formats and partitions drives automatically using `disko`
3. Generates hardware configuration
4. Executes `nixos-install --flake .#<profile>`
5. Clones repository into the user's home (`/home/<username>/Zero/nixos-config`)
