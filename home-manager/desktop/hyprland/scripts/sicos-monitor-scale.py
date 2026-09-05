#!/usr/bin/env python3

# sicos-monitor-scale.py - Manage and persist Hyprland monitor scaling for SicOS
# Usage:
#   sicos-monitor-scale.py --list
#   sicos-monitor-scale.py --set <MONITOR_NAME> <SCALE_VALUE>

import sys
import os
import json
import subprocess
import re
import socket
import math
import time
from pathlib import Path

KANSHI_REPO_CONFIG = Path.home() / "Zero/nixos-config/home-manager/desktop/hyprland/programs/kanshi/config"
KANSHI_MODULE_CONFIG = Path.home() / "Zero/nixos-config/modules/sicos/hyprland/config-files/kanshi/config"
KANSHI_LOCAL_CONFIG = Path.home() / ".config/kanshi/config"


def sync_local_kanshi_config():
    """Ensure ~/.config/kanshi/config points directly to the repository config if it points to /nix/store."""
    try:
        if KANSHI_LOCAL_CONFIG.is_symlink():
            target = str(KANSHI_LOCAL_CONFIG.resolve())
            if "/nix/store/" in target:
                KANSHI_LOCAL_CONFIG.unlink()
                KANSHI_LOCAL_CONFIG.symlink_to(KANSHI_REPO_CONFIG)
        elif not KANSHI_LOCAL_CONFIG.exists():
            KANSHI_LOCAL_CONFIG.parent.mkdir(parents=True, exist_ok=True)
            KANSHI_LOCAL_CONFIG.symlink_to(KANSHI_REPO_CONFIG)
    except Exception as e:
        sys.stderr.write(f"Warning: Could not sync local Kanshi config symlink: {e}\n")


def get_monitors():
    """Fetch monitor details via hyprctl JSON output."""
    try:
        res = subprocess.run(["hyprctl", "monitors", "-j"], capture_output=True, text=True, check=True)
        return json.loads(res.stdout)
    except Exception:
        return []


def list_monitors():
    """Output monitor list formatted for QuickShell."""
    monitors = get_monitors()
    output = []
    for m in monitors:
        output.append({
            "id": m.get("id"),
            "name": m.get("name"),
            "description": m.get("description", ""),
            "make": m.get("make", ""),
            "model": m.get("model", ""),
            "width": m.get("width"),
            "height": m.get("height"),
            "refreshRate": m.get("refreshRate"),
            "scale": m.get("scale"),
            "focused": m.get("focused")
        })
    print(json.dumps(output))


def get_closest_valid_scale(requested_scale, width, height):
    """Calculate nearest valid scale factor supported by Hyprland for monitor resolution."""
    if not width or not height or width <= 0 or height <= 0:
        return round(requested_scale, 6)

    g = math.gcd(int(width * 120), int(height * 120))
    k = round(requested_scale * 120)

    divisors = []
    for i in range(1, int(math.isqrt(g)) + 1):
        if g % i == 0:
            divisors.append(i)
            divisors.append(g // i)
    divisors = sorted(list(set(divisors)))

    closest_k = min(divisors, key=lambda d: abs(d - k))
    return round(closest_k / 120.0, 6)


def apply_live_scale(monitor_name, target_scale):
    """Apply scale factor directly to Hyprland via hyprctl eval IPC."""
    monitors = get_monitors()
    target_mon = next((m for m in monitors if m.get("name") == monitor_name), None)

    if not target_mon:
        sys.stderr.write(f"Error: Monitor '{monitor_name}' not found.\n")
        return False

    width = target_mon.get("width")
    height = target_mon.get("height")
    refresh_rate = target_mon.get("refreshRate")
    pos_x = target_mon.get("x", 0)
    pos_y = target_mon.get("y", 0)

    cmd1 = f'hl.monitor({{ output = "{monitor_name}", mode = "{width}x{height}@{refresh_rate}", position = "{pos_x}x{pos_y}", scale = {target_scale} }})'
    res1 = subprocess.run(["hyprctl", "eval", cmd1], capture_output=True, text=True)

    if res1.returncode != 0:
        cmd2 = f'hl.monitor({{ output = "{monitor_name}", mode = "preferred", position = "auto", scale = {target_scale} }})'
        subprocess.run(["hyprctl", "eval", cmd2], capture_output=True, text=True)

    return True


def extract_criteria(line):
    """Extract monitor output criteria string from a Kanshi config output line."""
    stripped = line.strip()
    if not stripped.startswith("output "):
        return None
    rest = stripped[7:].strip()
    if rest.startswith('"'):
        end_idx = rest.find('"', 1)
        if end_idx != -1:
            return rest[1:end_idx]
    elif rest.startswith("'"):
        end_idx = rest.find("'", 1)
        if end_idx != -1:
            return rest[1:end_idx]
    else:
        return rest.split()[0]
    return None


def check_match(line, mon_name, mon_desc, mon_make, mon_model):
    """Check if a Kanshi output line corresponds to the given monitor attributes."""
    criteria = extract_criteria(line)
    if not criteria:
        return False

    clean_criteria = re.sub(r'(\s+Unknown|\*)+$', '', criteria, flags=re.IGNORECASE).strip()
    clean_desc = re.sub(r'(\s+Unknown|\*)+$', '', mon_desc, flags=re.IGNORECASE).strip()

    if criteria == mon_name or clean_criteria == mon_name:
        return True
    if clean_criteria and clean_desc and (clean_criteria == clean_desc):
        return True
    if clean_criteria and clean_desc and len(clean_criteria) >= 3 and len(clean_desc) >= 3:
        if clean_criteria in clean_desc or clean_desc in clean_criteria:
            return True

    if mon_make and mon_model:
        make_model = f"{mon_make} {mon_model}".strip()
        if clean_criteria in make_model or make_model in clean_criteria:
            return True

    return False


def update_kanshi_config(config_path, monitor_name, new_scale):
    """Update scale value in the target Kanshi configuration file on disk."""
    if not config_path.exists() or not os.access(config_path, os.W_OK):
        return False

    monitors = get_monitors()
    target_mon = next((m for m in monitors if m.get("name") == monitor_name), {})
    mon_desc = target_mon.get("description", "")
    mon_make = target_mon.get("make", "")
    mon_model = target_mon.get("model", "")

    hostname = socket.gethostname().lower()

    try:
        with open(config_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except Exception:
        return False

    updated = False
    new_lines = []
    in_matching_profile = False

    # Pass 1: Match within profile block corresponding to current hostname
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("profile "):
            prof_name = stripped.split()[1].lower()
            in_matching_profile = hostname in prof_name
        elif stripped == "}":
            in_matching_profile = False
        elif in_matching_profile and stripped.startswith("output "):
            if check_match(line, monitor_name, mon_desc, mon_make, mon_model):
                if "scale " in line:
                    line = re.sub(r'(scale\s+)[0-9.]+', r'\g<1>' + f"{new_scale:.6f}".rstrip('0').rstrip('.'), line)
                    updated = True
                elif "enable" in line:
                    line = line.rstrip('\n') + f" scale {new_scale:.6f}".rstrip('0').rstrip('.') + "\n"
                    updated = True

        new_lines.append(line)

    # Pass 2: Fallback to match in any profile block
    if not updated:
        new_lines = []
        for line in lines:
            stripped = line.strip()
            if stripped.startswith("output "):
                if check_match(line, monitor_name, mon_desc, mon_make, mon_model):
                    if "scale " in line:
                        line = re.sub(r'(scale\s+)[0-9.]+', r'\g<1>' + f"{new_scale:.6f}".rstrip('0').rstrip('.'), line)
                        updated = True
                    elif "enable" in line:
                        line = line.rstrip('\n') + f" scale {new_scale:.6f}".rstrip('0').rstrip('.') + "\n"
                        updated = True
            new_lines.append(line)

    if updated:
        try:
            with open(config_path, "w", encoding="utf-8") as f:
                f.writelines(new_lines)
            return True
        except Exception:
            return False

    return False


def reload_kanshi_if_running():
    """Reload Kanshi daemon if active so it updates its in-memory profile."""
    try:
        pgrep = subprocess.run(["pgrep", "-x", "kanshi"], capture_output=True)
        if pgrep.returncode == 0:
            subprocess.run(["kanshictl", "reload"], capture_output=True)
            return
        
        systemctl = subprocess.run(["systemctl", "--user", "is-active", "--quiet", "kanshi.service"])
        if systemctl.returncode == 0:
            subprocess.run(["systemctl", "--user", "reload", "kanshi.service"], capture_output=True)
    except Exception:
        pass


def set_monitor_scale(monitor_name, requested_scale_str):
    """Main workflow to set and persist monitor scale."""
    try:
        requested_scale = float(requested_scale_str)
    except ValueError:
        sys.stderr.write(f"Error: Invalid scale value '{requested_scale_str}'\n")
        sys.exit(1)

    sync_local_kanshi_config()

    monitors = get_monitors()
    target_mon = next((m for m in monitors if m.get("name") == monitor_name), {})
    width = target_mon.get("width", 0)
    height = target_mon.get("height", 0)

    # 1. Calculate nearest valid scale divisor for Hyprland
    valid_scale = get_closest_valid_scale(requested_scale, width, height)

    # 2. Apply live scale via Hyprland IPC
    apply_live_scale(monitor_name, valid_scale)

    time.sleep(0.05)

    # 3. Read actual applied scale factor from Hyprland IPC if settled
    settled_monitors = get_monitors()
    settled_mon = next((m for m in settled_monitors if m.get("name") == monitor_name), None)
    actual_scale = settled_mon.get("scale") if settled_mon else valid_scale
    persist_scale = actual_scale if actual_scale is not None else valid_scale

    # 4. Update Kanshi configs on disk with valid applied scale
    update_kanshi_config(KANSHI_REPO_CONFIG, monitor_name, persist_scale)
    update_kanshi_config(KANSHI_MODULE_CONFIG, monitor_name, persist_scale)
    update_kanshi_config(KANSHI_LOCAL_CONFIG, monitor_name, persist_scale)

    # 5. Reload Kanshi if running
    reload_kanshi_if_running()

    print(f"Applied and persisted scale {persist_scale} (requested: {requested_scale}) for {monitor_name}.")


def main():
    if len(sys.argv) < 2:
        print("Usage: sicos-monitor-scale.py {--list|--set <MONITOR_NAME> <SCALE_VALUE>}", file=sys.stderr)
        sys.exit(1)

    mode = sys.argv[1]

    if mode == "--list":
        list_monitors()
    elif mode == "--set":
        if len(sys.argv) < 4:
            print("Usage: sicos-monitor-scale.py --set <MONITOR_NAME> <SCALE_VALUE>", file=sys.stderr)
            sys.exit(1)
        mon_name = sys.argv[2]
        scale_val = sys.argv[3]
        set_monitor_scale(mon_name, scale_val)
    else:
        print(f"Unknown argument: {mode}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
