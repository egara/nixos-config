#!/usr/bin/env python3

# sicos-monitors.py - Monitor and Kanshi profile manager backend for SicOS-Bar
#
# Usage:
#   sicos-monitors.py --status
#   sicos-monitors.py --toggle <MONITOR_NAME>
#   sicos-monitors.py --set <MONITOR_NAME> <enable|disable>

import sys
import os
import json
import subprocess
import re
import socket
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


def is_kanshi_available():
    """Check if Kanshi is installed and if configuration files exist."""
    # Check binary
    kanshi_bin = subprocess.run(["which", "kanshi"], capture_output=True, text=True)
    has_bin = (kanshi_bin.returncode == 0)

    # Check config
    has_config = (
        KANSHI_LOCAL_CONFIG.exists()
        or KANSHI_REPO_CONFIG.exists()
        or KANSHI_MODULE_CONFIG.exists()
    )

    # Check daemon running
    pgrep = subprocess.run(["pgrep", "-x", "kanshi"], capture_output=True)
    is_running = (pgrep.returncode == 0)

    return {
        "installed": has_bin,
        "config_exists": has_config,
        "running": is_running,
        "enabled": (has_bin and has_config)
    }


def get_hyprland_monitors():
    """Fetch all monitors from hyprctl monitors all -j (including inactive/disabled)."""
    try:
        res = subprocess.run(["hyprctl", "monitors", "all", "-j"], capture_output=True, text=True, check=True)
        return json.loads(res.stdout)
    except Exception:
        # Fallback to active monitors if 'all' fails
        try:
            res = subprocess.run(["hyprctl", "monitors", "-j"], capture_output=True, text=True, check=True)
            return json.loads(res.stdout)
        except Exception:
            return []


def get_kanshi_config_file():
    """Get the active writable Kanshi config file."""
    for p in [KANSHI_REPO_CONFIG, KANSHI_LOCAL_CONFIG, KANSHI_MODULE_CONFIG]:
        if p.exists() and os.access(p, os.R_OK):
            return p
    return None


def parse_kanshi_profiles():
    """Parse profiles from Kanshi config for the current host and all hosts."""
    cfg_file = get_kanshi_config_file()
    if not cfg_file:
        return {}

    hostname = socket.gethostname().lower()
    profiles = {}
    current_profile = None

    try:
        with open(cfg_file, "r", encoding="utf-8") as f:
            for line in f:
                stripped = line.strip()
                if not stripped or stripped.startswith("#"):
                    continue

                if stripped.startswith("profile ") and stripped.endswith("{"):
                    prof_name = stripped.split()[1]
                    current_profile = prof_name
                    profiles[current_profile] = {
                        "name": prof_name,
                        "matches_host": (hostname in prof_name.lower()),
                        "outputs": []
                    }
                elif stripped == "}":
                    current_profile = None
                elif current_profile and stripped.startswith("output "):
                    # output "criteria" status [mode WxH] [position X,Y] [scale S]
                    rest = stripped[7:].strip()
                    criteria = None
                    if rest.startswith('"'):
                        end_idx = rest.find('"', 1)
                        if end_idx != -1:
                            criteria = rest[1:end_idx]
                            rest = rest[end_idx + 1:].strip()
                    elif rest.startswith("'"):
                        end_idx = rest.find("'", 1)
                        if end_idx != -1:
                            criteria = rest[1:end_idx]
                            rest = rest[end_idx + 1:].strip()
                    else:
                        parts = rest.split(None, 1)
                        criteria = parts[0]
                        rest = parts[1] if len(parts) > 1 else ""

                    status = "enable" if "enable" in rest.split() else ("disable" if "disable" in rest.split() else "enable")

                    mode_match = re.search(r'mode\s+([0-9x@.]+)', rest)
                    mode = mode_match.group(1) if mode_match else ""

                    scale_match = re.search(r'scale\s+([0-9.]+)', rest)
                    scale = float(scale_match.group(1)) if scale_match else 1.0

                    pos_match = re.search(r'position\s+([0-9,-]+)', rest)
                    position = pos_match.group(1) if pos_match else "0,0"

                    profiles[current_profile]["outputs"].append({
                        "criteria": criteria,
                        "status": status,
                        "mode": mode,
                        "scale": scale,
                        "position": position,
                        "raw": stripped
                    })
    except Exception as e:
        sys.stderr.write(f"Error parsing Kanshi profiles: {e}\n")

    return profiles


def match_criteria(criteria, mon):
    """Check if criteria string matches monitor details."""
    if not criteria or not mon:
        return False

    clean_criteria = re.sub(r'(\s+Unknown|\*)+$', '', criteria, flags=re.IGNORECASE).strip()
    mon_name = mon.get("name", "")
    mon_desc = mon.get("description", "")
    clean_desc = re.sub(r'(\s+Unknown|\*)+$', '', mon_desc, flags=re.IGNORECASE).strip()
    make_model = f"{mon.get('make', '')} {mon.get('model', '')}".strip()

    if criteria == mon_name or clean_criteria == mon_name:
        return True
    if clean_criteria and clean_desc and (clean_criteria == clean_desc):
        return True
    if clean_criteria and clean_desc and len(clean_criteria) >= 3 and len(clean_desc) >= 3:
        if clean_criteria in clean_desc or clean_desc in clean_criteria:
            return True
    if make_model and (clean_criteria in make_model or make_model in clean_criteria):
        return True

    return False


def detect_active_profile(profiles, monitors):
    """Determine which Kanshi profile matches the current system state."""
    hostname = socket.gethostname().lower()
    host_profiles = [p for p in profiles.values() if p["matches_host"]]
    if not host_profiles:
        host_profiles = list(profiles.values())

    best_profile = None
    best_score = -1

    for prof in host_profiles:
        score = 0
        outputs = prof["outputs"]

        for out in outputs:
            matched_mon = next((m for m in monitors if match_criteria(out["criteria"], m)), None)
            if matched_mon:
                is_disabled = matched_mon.get("disabled", False)
                mon_status = "disable" if is_disabled else "enable"

                if out["status"] == mon_status:
                    score += 2
                else:
                    score += 1
            else:
                # If profile specifies a monitor that is not connected at all
                if out["status"] == "enable":
                    score -= 3

        if score > best_score:
            best_score = score
            best_profile = prof["name"]

    return best_profile


def reload_kanshi():
    """Reload Kanshi daemon if active."""
    try:
        pgrep = subprocess.run(["pgrep", "-x", "kanshi"], capture_output=True)
        if pgrep.returncode == 0:
            subprocess.run(["kanshictl", "reload"], capture_output=True)
            return True

        systemctl = subprocess.run(["systemctl", "--user", "is-active", "--quiet", "kanshi.service"])
        if systemctl.returncode == 0:
            subprocess.run(["systemctl", "--user", "reload", "kanshi.service"], capture_output=True)
            return True
    except Exception:
        pass
    return False


def get_status():
    """Generate comprehensive JSON status for QuickShell."""
    kanshi_info = is_kanshi_available()
    monitors_raw = get_hyprland_monitors()
    profiles = parse_kanshi_profiles() if kanshi_info["enabled"] else {}
    active_profile = detect_active_profile(profiles, monitors_raw) if profiles else ""

    host_profiles_list = [p["name"] for p in profiles.values() if p["matches_host"]]
    if not host_profiles_list and profiles:
        host_profiles_list = list(profiles.keys())

    monitors_processed = []
    for m in monitors_raw:
        is_disabled = m.get("disabled", False)

        # Check if Kanshi profile has rules for this monitor
        kanshi_status = "unknown"
        if active_profile and active_profile in profiles:
            for out in profiles[active_profile]["outputs"]:
                if match_criteria(out["criteria"], m):
                    kanshi_status = out["status"]
                    break

        monitors_processed.append({
            "id": m.get("id"),
            "name": m.get("name"),
            "description": m.get("description", ""),
            "make": m.get("make", ""),
            "model": m.get("model", ""),
            "enabled": not is_disabled,
            "width": m.get("width", 0),
            "height": m.get("height", 0),
            "refreshRate": round(m.get("refreshRate", 0), 1),
            "scale": round(m.get("scale", 1.0), 3),
            "x": m.get("x", 0),
            "y": m.get("y", 0),
            "focused": m.get("focused", False),
            "kanshi_status": kanshi_status,
            "availableModes": m.get("availableModes", [])
        })

    result = {
        "kanshi_enabled": kanshi_info["enabled"],
        "kanshi_running": kanshi_info["running"],
        "active_profile": active_profile,
        "profiles": host_profiles_list,
        "monitors": monitors_processed,
        "hostname": socket.gethostname()
    }
    print(json.dumps(result, indent=2))
    return result


def get_max_available_mode(modes):
    """Find the highest resolution and refresh rate mode from a list of available modes."""
    if not modes:
        return ""
    def parse_mode_tuple(m_str):
        clean = re.sub(r'Hz$', '', m_str.strip(), flags=re.IGNORECASE)
        match = re.match(r'^(\d+)x(\d+)(?:@([\d.]+))?$', clean)
        if match:
            w, h = int(match.group(1)), int(match.group(2))
            r = float(match.group(3)) if match.group(3) else 60.0
            return (w * h, w, h, r, clean)
        return (0, 0, 0, 0.0, clean)
    best_mode = max(modes, key=parse_mode_tuple)
    return parse_mode_tuple(best_mode)[4]


def resolve_monitor_defaults(profiles, target_mon):
    """Search all profiles for this machine to find configured mode, scale, and position, falling back to max resolution and scale 1.0."""
    hostname = socket.gethostname().lower()
    default_mode = ""
    default_scale = None
    default_pos = None

    # First search matching host profiles
    host_profs = [p for p in profiles.values() if p.get("matches_host")]
    if not host_profs:
        host_profs = list(profiles.values())

    for prof in host_profs:
        for out in prof["outputs"]:
            if match_criteria(out["criteria"], target_mon):
                if out.get("mode") and not default_mode:
                    default_mode = out["mode"]
                if out.get("scale") and default_scale is None:
                    default_scale = out["scale"]
                if out.get("position") and out["position"] != "0,0" and default_pos is None:
                    default_pos = out["position"]

    # Fallback to maximum supported mode if no mode configured
    if not default_mode:
        avail = target_mon.get("availableModes", [])
        if avail:
            default_mode = get_max_available_mode(avail)

    # Fallback scale to 1.0 if not specified
    if default_scale is None:
        default_scale = 1.0

    return {
        "mode": default_mode,
        "scale": default_scale,
        "position": default_pos
    }


def calculate_non_overlapping_position(active_monitors, target_mon, fallback_pos=None):
    """Calculate an adjacent, non-overlapping (X, Y) coordinate next to existing active monitors."""
    if fallback_pos and fallback_pos != "0,0":
        try:
            fx, fy = map(int, fallback_pos.replace("x", ",").split(","))
            return fx, fy
        except Exception:
            pass

    if not active_monitors:
        return 0, 0

    # Place to the right of the rightmost monitor: X = max(X_i + Width_i / Scale_i)
    max_right = 0
    for m in active_monitors:
        mx = m.get("x", 0)
        mw = m.get("width") or 1920
        mscale = m.get("scale") or 1.0
        effective_w = int(round(mw / mscale))
        right_edge = mx + effective_w
        if right_edge > max_right:
            max_right = right_edge

    return max_right, 0


def update_kanshi_output_status(config_path, active_profile, monitor_name, new_status, new_pos_str=None, new_mode_str=None, new_scale_val=None):
    """Update enable/disable status for monitor in target Kanshi config file with correct position and mode."""
    if not config_path.exists() or not os.access(config_path, os.W_OK):
        return False

    monitors = get_hyprland_monitors()
    target_mon = next((m for m in monitors if m.get("name") == monitor_name), {})

    try:
        with open(config_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except Exception:
        return False

    updated = False
    new_lines = []
    in_profile = False

    for line in lines:
        stripped = line.strip()
        if stripped.startswith("profile "):
            pname = stripped.split()[1]
            in_profile = (pname == active_profile)
        elif stripped == "}":
            in_profile = False
        elif in_profile and stripped.startswith("output "):
            criteria = None
            rest = stripped[7:].strip()
            if rest.startswith('"'):
                end_idx = rest.find('"', 1)
                if end_idx != -1:
                    criteria = rest[1:end_idx]
            elif rest.startswith("'"):
                end_idx = rest.find("'", 1)
                if end_idx != -1:
                    criteria = rest[1:end_idx]
            else:
                criteria = rest.split()[0]

            if match_criteria(criteria, target_mon):
                if new_status == "disable":
                    crit_prefix = f'output "{criteria}"' if '"' in line else f"output {criteria}"
                    indent = line[:len(line) - len(line.lstrip())]
                    line = f"{indent}{crit_prefix} disable\n"
                    updated = True
                elif new_status == "enable":
                    width = target_mon.get("width") or 1920
                    height = target_mon.get("height") or 1080
                    mode = new_mode_str or f"{width}x{height}"
                    scale = new_scale_val if new_scale_val is not None else (target_mon.get("scale") or 1.0)
                    pos = new_pos_str or "0,0"

                    crit_prefix = f'output "{criteria}"' if '"' in line else f"output {criteria}"
                    indent = line[:len(line) - len(line.lstrip())]
                    line = f"{indent}{crit_prefix} enable mode {mode} position {pos} scale {scale:.6f}".rstrip('0').rstrip('.') + "\n"
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


def set_monitor_status(monitor_name, target_status):
    """Enable or disable monitor live in Hyprland and persist in Kanshi config with auto-positioning."""
    sync_local_kanshi_config()
    monitors = get_hyprland_monitors()
    target_mon = next((m for m in monitors if m.get("name") == monitor_name), None)

    if not target_mon:
        sys.stderr.write(f"Error: Monitor '{monitor_name}' not found.\n")
        sys.exit(1)

    profiles = parse_kanshi_profiles()
    active_profile = detect_active_profile(profiles, monitors)

    if target_status == "disable":
        if active_profile:
            for p in [KANSHI_REPO_CONFIG, KANSHI_LOCAL_CONFIG, KANSHI_MODULE_CONFIG]:
                update_kanshi_output_status(p, active_profile, monitor_name, "disable")

        cmd = f'hl.monitor({{ output = "{monitor_name}", mode = "disable" }})'
        subprocess.run(["hyprctl", "eval", cmd], capture_output=True, text=True)
    else:
        # Resolving non-overlapping position & defaults
        defaults = resolve_monitor_defaults(profiles, target_mon)
        active_monitors = [m for m in monitors if not m.get("disabled", False) and m.get("name") != monitor_name]

        pos_x, pos_y = calculate_non_overlapping_position(active_monitors, target_mon, defaults.get("position"))
        pos_str = f"{pos_x},{pos_y}"

        width = target_mon.get("width") or 1920
        height = target_mon.get("height") or 1080
        rate = target_mon.get("refreshRate") or 60
        mode_str = defaults.get("mode") or f"{width}x{height}@{rate}"
        scale_val = defaults.get("scale") if defaults.get("scale") is not None else (target_mon.get("scale") or 1.0)

        # 1. Update Kanshi files
        if active_profile:
            for p in [KANSHI_REPO_CONFIG, KANSHI_LOCAL_CONFIG, KANSHI_MODULE_CONFIG]:
                update_kanshi_output_status(p, active_profile, monitor_name, "enable", pos_str, mode_str, scale_val)

        # 2. Apply live state in Hyprland
        cmd = f'hl.monitor({{ output = "{monitor_name}", mode = "{mode_str}", position = "{pos_x}x{pos_y}", scale = {scale_val} }})'
        res = subprocess.run(["hyprctl", "eval", cmd], capture_output=True, text=True)
        if res.returncode != 0:
            cmd2 = f'hl.monitor({{ output = "{monitor_name}", mode = "preferred", position = "{pos_x}x{pos_y}", scale = {scale_val} }})'
            subprocess.run(["hyprctl", "eval", cmd2], capture_output=True, text=True)

    reload_kanshi()
    time.sleep(0.1)
    print(f"Monitor '{monitor_name}' set to {target_status} successfully.")


def toggle_monitor(monitor_name):
    """Toggle monitor enabled/disabled state."""
    monitors = get_hyprland_monitors()
    target_mon = next((m for m in monitors if m.get("name") == monitor_name), None)

    if not target_mon:
        sys.stderr.write(f"Error: Monitor '{monitor_name}' not found.\n")
        sys.exit(1)

    is_disabled = target_mon.get("disabled", False)
    new_status = "enable" if is_disabled else "disable"
    set_monitor_status(monitor_name, new_status)


def update_kanshi_output_mode(config_path, active_profile, monitor_name, new_mode):
    """Update mode (resolution) for monitor in target Kanshi config file."""
    if not config_path.exists() or not os.access(config_path, os.W_OK):
        return False

    monitors = get_hyprland_monitors()
    target_mon = next((m for m in monitors if m.get("name") == monitor_name), {})

    try:
        with open(config_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except Exception:
        return False

    updated = False
    new_lines = []
    in_profile = False

    for line in lines:
        stripped = line.strip()
        if stripped.startswith("profile "):
            pname = stripped.split()[1]
            in_profile = (pname == active_profile)
        elif stripped == "}":
            in_profile = False
        elif in_profile and stripped.startswith("output "):
            criteria = None
            rest = stripped[7:].strip()
            if rest.startswith('"'):
                end_idx = rest.find('"', 1)
                if end_idx != -1:
                    criteria = rest[1:end_idx]
            elif rest.startswith("'"):
                end_idx = rest.find("'", 1)
                if end_idx != -1:
                    criteria = rest[1:end_idx]
            else:
                criteria = rest.split()[0]

            if match_criteria(criteria, target_mon):
                clean_mode = re.sub(r'Hz$', '', new_mode.strip(), flags=re.IGNORECASE)
                m_match = re.match(r'^(\d+x\d+)(?:@([\d.]+))?$', clean_mode)
                if m_match:
                    res_part, rate_part = m_match.group(1), m_match.group(2)
                    if rate_part:
                        rf = float(rate_part)
                        rate_str = f"{rf:.2f}" if rf % 1 else f"{int(rf)}"
                        clean_mode = f"{res_part}@{rate_str}"
                    else:
                        clean_mode = res_part

                if "mode " in line:
                    line = re.sub(r'(mode\s+)[0-9a-zA-Z@.]+', r'\g<1>' + clean_mode, line)
                    updated = True
                elif "enable" in line:
                    line = line.replace("enable", f"enable mode {clean_mode}", 1)
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


def update_kanshi_output_position(config_path, active_profile, monitor_name, new_x, new_y):
    """Update position for monitor in target Kanshi config file."""
    if not config_path.exists() or not os.access(config_path, os.W_OK):
        return False

    monitors = get_hyprland_monitors()
    target_mon = next((m for m in monitors if m.get("name") == monitor_name), {})

    try:
        with open(config_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except Exception:
        return False

    updated = False
    new_lines = []
    in_profile = False
    pos_str = f"{new_x},{new_y}"

    for line in lines:
        stripped = line.strip()
        if stripped.startswith("profile "):
            pname = stripped.split()[1]
            in_profile = (pname == active_profile)
        elif stripped == "}":
            in_profile = False
        elif in_profile and stripped.startswith("output "):
            criteria = None
            rest = stripped[7:].strip()
            if rest.startswith('"'):
                end_idx = rest.find('"', 1)
                if end_idx != -1:
                    criteria = rest[1:end_idx]
            elif rest.startswith("'"):
                end_idx = rest.find("'", 1)
                if end_idx != -1:
                    criteria = rest[1:end_idx]
            else:
                criteria = rest.split()[0]

            if match_criteria(criteria, target_mon):
                if "position " in line:
                    line = re.sub(r'(position\s+)[0-9,-]+', r'\g<1>' + pos_str, line)
                    updated = True
                else:
                    # Append position before scale or at end
                    if "scale " in line:
                        line = line.replace("scale ", f"position {pos_str} scale ", 1)
                    else:
                        line = line.rstrip() + f" position {pos_str}\n"
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


def set_monitor_position(monitor_name, pos_x, pos_y):
    """Set monitor position live and in Kanshi."""
    sync_local_kanshi_config()
    monitors = get_hyprland_monitors()
    target_mon = next((m for m in monitors if m.get("name") == monitor_name), None)

    if not target_mon:
        sys.stderr.write(f"Error: Monitor '{monitor_name}' not found.\n")
        sys.exit(1)

    profiles = parse_kanshi_profiles()
    active_profile = detect_active_profile(profiles, monitors)

    if active_profile:
        for p in [KANSHI_REPO_CONFIG, KANSHI_LOCAL_CONFIG, KANSHI_MODULE_CONFIG]:
            update_kanshi_output_position(p, active_profile, monitor_name, pos_x, pos_y)

    width = target_mon.get("width") or 1920
    height = target_mon.get("height") or 1080
    rate = target_mon.get("refreshRate") or 60
    scale = target_mon.get("scale") or 1.0

    cmd = f'hl.monitor({{ output = "{monitor_name}", mode = "{width}x{height}@{rate}", position = "{pos_x}x{pos_y}", scale = {scale} }})'
    subprocess.run(["hyprctl", "eval", cmd], capture_output=True, text=True)

    reload_kanshi()
    time.sleep(0.1)
    print(f"Monitor '{monitor_name}' position set to '{pos_x},{pos_y}' successfully.")


def set_monitor_layout(layout_str):
    """Set multiple monitor positions at once. Format: 'MON1:X,Y MON2:X,Y'."""
    sync_local_kanshi_config()
    monitors = get_hyprland_monitors()
    profiles = parse_kanshi_profiles()
    active_profile = detect_active_profile(profiles, monitors)

    pairs = layout_str.strip().split()
    for pair in pairs:
        if ":" not in pair:
            continue
        m_name, coords = pair.split(":", 1)
        if "," not in coords:
            continue
        try:
            x_str, y_str = coords.split(",")
            px, py = int(x_str), int(y_str)
        except ValueError:
            continue

        target_mon = next((m for m in monitors if m.get("name") == m_name), None)
        if not target_mon:
            continue

        if active_profile:
            for p in [KANSHI_REPO_CONFIG, KANSHI_LOCAL_CONFIG, KANSHI_MODULE_CONFIG]:
                update_kanshi_output_position(p, active_profile, m_name, px, py)

        width = target_mon.get("width") or 1920
        height = target_mon.get("height") or 1080
        rate = target_mon.get("refreshRate") or 60
        scale = target_mon.get("scale") or 1.0

        cmd = f'hl.monitor({{ output = "{m_name}", mode = "{width}x{height}@{rate}", position = "{px}x{py}", scale = {scale} }})'
        subprocess.run(["hyprctl", "eval", cmd], capture_output=True, text=True)

    reload_kanshi()
    time.sleep(0.1)
    print(f"Monitor layout '{layout_str}' applied successfully.")


def set_monitor_mode(monitor_name, target_mode):
    """Change monitor resolution/mode live in Hyprland and persist in Kanshi config."""
    sync_local_kanshi_config()
    monitors = get_hyprland_monitors()
    target_mon = next((m for m in monitors if m.get("name") == monitor_name), None)

    if not target_mon:
        sys.stderr.write(f"Error: Monitor '{monitor_name}' not found.\n")
        sys.exit(1)

    # Standardize mode for Hyprland and Kanshi
    clean_mode = re.sub(r'Hz$', '', target_mode.strip(), flags=re.IGNORECASE)
    m_match = re.match(r'^(\d+x\d+)(?:@([\d.]+))?$', clean_mode)
    if m_match:
        res_part, rate_part = m_match.group(1), m_match.group(2)
        if rate_part:
            rf = float(rate_part)
            rate_str = f"{rf:.2f}" if rf % 1 else f"{int(rf)}"
            clean_mode = f"{res_part}@{rate_str}"
        else:
            clean_mode = res_part

    profiles = parse_kanshi_profiles()
    active_profile = detect_active_profile(profiles, monitors)

    # 1. Update Kanshi files on disk
    if active_profile:
        for p in [KANSHI_REPO_CONFIG, KANSHI_LOCAL_CONFIG, KANSHI_MODULE_CONFIG]:
            update_kanshi_output_mode(p, active_profile, monitor_name, clean_mode)

    # 2. Apply live state in Hyprland
    pos_x = target_mon.get("x", 0)
    pos_y = target_mon.get("y", 0)
    scale = target_mon.get("scale") or 1.0

    cmd = f'hl.monitor({{ output = "{monitor_name}", mode = "{clean_mode}", position = "{pos_x}x{pos_y}", scale = {scale} }})'
    res = subprocess.run(["hyprctl", "eval", cmd], capture_output=True, text=True)
    if res.returncode != 0:
        cmd2 = f'hl.monitor({{ output = "{monitor_name}", mode = "{clean_mode}", position = "auto", scale = {scale} }})'
        subprocess.run(["hyprctl", "eval", cmd2], capture_output=True, text=True)

    # 3. Reload Kanshi if running
    reload_kanshi()
    time.sleep(0.1)

    print(f"Monitor '{monitor_name}' mode set to '{clean_mode}' successfully.")


def main():
    if len(sys.argv) < 2 or sys.argv[1] in ["-h", "--help"]:
        print("Usage: sicos-monitors.py {--status|--toggle <MONITOR_NAME>|--set <MONITOR_NAME> <enable|disable>|--mode <MONITOR_NAME> <MODE>|--position <MONITOR_NAME> <X> <Y>|--layout <LAYOUT_STRING>}")
        sys.exit(0)

    cmd = sys.argv[1]
    if cmd == "--status":
        get_status()
    elif cmd == "--toggle":
        if len(sys.argv) < 3:
            sys.stderr.write("Usage: sicos-monitors.py --toggle <MONITOR_NAME>\n")
            sys.exit(1)
        toggle_monitor(sys.argv[2])
    elif cmd == "--set":
        if len(sys.argv) < 4:
            sys.stderr.write("Usage: sicos-monitors.py --set <MONITOR_NAME> <enable|disable>\n")
            sys.exit(1)
        set_monitor_status(sys.argv[2], sys.argv[3])
    elif cmd == "--mode":
        if len(sys.argv) < 4:
            sys.stderr.write("Usage: sicos-monitors.py --mode <MONITOR_NAME> <MODE>\n")
            sys.exit(1)
        set_monitor_mode(sys.argv[2], sys.argv[3])
    elif cmd == "--position":
        if len(sys.argv) < 5:
            sys.stderr.write("Usage: sicos-monitors.py --position <MONITOR_NAME> <X> <Y>\n")
            sys.exit(1)
        set_monitor_position(sys.argv[2], int(sys.argv[3]), int(sys.argv[4]))
    elif cmd == "--layout":
        if len(sys.argv) < 3:
            sys.stderr.write("Usage: sicos-monitors.py --layout '<MON1:X,Y MON2:X,Y>'\n")
            sys.exit(1)
        set_monitor_layout(sys.argv[2])
    else:
        sys.stderr.write(f"Unknown command: {cmd}\n")
        sys.exit(1)


if __name__ == "__main__":
    main()

