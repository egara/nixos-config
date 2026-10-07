#!/usr/bin/env python3
import json
import os
import re
import shutil
import subprocess

def format_size(bytes_val):
    for unit in ['B', 'KiB', 'MiB', 'GiB', 'TiB']:
        if bytes_val < 1024.0 or unit == 'TiB':
            return f"{bytes_val:.2f}{unit}" if unit in ['GiB', 'TiB'] else f"{bytes_val:.1f}{unit}"
        bytes_val /= 1024.0
    return f"{bytes_val:.2f}TiB"

def main():
    data = {
        "is_btrfs": False,
        "total_bytes": 0,
        "total_str": "0 GiB",
        "used_bytes": 0,
        "used_str": "0 GiB",
        "free_bytes": 0,
        "free_str": "0 GiB",
        "used_pct": 0.0,
        "alloc_bytes": 0,
        "alloc_str": "0 GiB",
        "alloc_pct": 0.0,
        "data_allocated_bytes": 0,
        "data_allocated_str": "0 GiB",
        "data_used_bytes": 0,
        "data_used_str": "0 GiB",
        "data_used_pct": 0.0,
        "meta_allocated_bytes": 0,
        "meta_allocated_str": "0 GiB",
        "meta_used_bytes": 0,
        "meta_used_str": "0 GiB",
        "meta_used_pct": 0.0,
        "status_text": "No problem, you have enough free space in your filesystem",
        "status_color": "ok", # ok, danger, ko
    }

    try:
        out = subprocess.check_output(
            ["btrfs", "filesystem", "usage", "--raw", "/"],
            stderr=subprocess.DEVNULL,
            text=True
        )

        def get_val(p):
            m = re.search(p, out)
            return int(m.group(1)) if m else 0

        dev_size = get_val(r"Device size:\s+(\d+)")
        dev_alloc = get_val(r"Device allocated:\s+(\d+)")
        used = get_val(r"Used:\s+(\d+)")
        free_est = get_val(r"Free \(estimated\):\s+(\d+)")

        data_m = re.search(r"Data,[^:]*:\s*Size:(\d+),\s*Used:(\d+)\s*\(([\d\.]+)%\)", out)
        meta_m = re.search(r"Metadata,[^:]*:\s*Size:(\d+),\s*Used:(\d+)\s*\(([\d\.]+)%\)", out)

        if dev_size > 0:
            data["is_btrfs"] = True
            data["total_bytes"] = dev_size
            data["total_str"] = format_size(dev_size)
            data["alloc_bytes"] = dev_alloc
            data["alloc_str"] = format_size(dev_alloc)
            alloc_pct = round((dev_alloc / dev_size * 100.0), 1)
            data["alloc_pct"] = alloc_pct
            data["used_bytes"] = used
            data["used_str"] = format_size(used)
            data["free_bytes"] = free_est
            data["free_str"] = format_size(free_est)
            data["used_pct"] = round((used / dev_size * 100.0), 1)

            if data_m:
                data["data_allocated_bytes"] = int(data_m.group(1))
                data["data_allocated_str"] = format_size(int(data_m.group(1)))
                data["data_used_bytes"] = int(data_m.group(2))
                data["data_used_str"] = format_size(int(data_m.group(2)))
                data["data_used_pct"] = round(float(data_m.group(3)), 1)

            if meta_m:
                data["meta_allocated_bytes"] = int(meta_m.group(1))
                data["meta_allocated_str"] = format_size(int(meta_m.group(1)))
                data["meta_used_bytes"] = int(meta_m.group(2))
                data["meta_used_str"] = format_size(int(meta_m.group(2)))
                data["meta_used_pct"] = round(float(meta_m.group(3)), 1)

            # ButterManager exact threshold logic based on total allocated vs total size:
            # <= 70%: ok
            # > 70% and <= 85%: danger
            # > 85%: ko
            if alloc_pct <= 70.0:
                data["status_text"] = "No problem, you have enough free space in your filesystem"
                data["status_color"] = "ok"
            elif alloc_pct <= 85.0:
                data["status_text"] = "Keep calm and clean a little bit your filesystem"
                data["status_color"] = "danger"
            else:
                data["status_text"] = "Low space available. Remove old snapshots, clean and balance"
                data["status_color"] = "ko"
    except Exception:
        pass

    if not data["is_btrfs"]:
        try:
            total, used, free = shutil.disk_usage("/")
            data["total_bytes"] = total
            data["total_str"] = format_size(total)
            data["alloc_bytes"] = used
            data["alloc_str"] = format_size(used)
            pct = round((used / total * 100.0), 1) if total else 0.0
            data["alloc_pct"] = pct
            data["used_bytes"] = used
            data["used_str"] = format_size(used)
            data["free_bytes"] = free
            data["free_str"] = format_size(free)
            data["used_pct"] = pct
            data["data_allocated_bytes"] = used
            data["data_allocated_str"] = format_size(used)
            data["data_used_bytes"] = used
            data["data_used_str"] = format_size(used)
            data["data_used_pct"] = pct

            if pct <= 70.0:
                data["status_text"] = "No problem, you have enough free space in your filesystem"
                data["status_color"] = "ok"
            elif pct <= 85.0:
                data["status_text"] = "Keep calm and clean a little bit your filesystem"
                data["status_color"] = "danger"
            else:
                data["status_text"] = "Low space available. Clean up your filesystem"
                data["status_color"] = "ko"
        except Exception:
            pass

    print(json.dumps(data))

if __name__ == "__main__":
    main()
