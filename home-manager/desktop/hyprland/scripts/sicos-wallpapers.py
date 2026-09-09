#!/usr/bin/env python3

# sicos-wallpapers.py - Wallpaper backend for SicOS-Bar
#
# Scans ~/.config/sicos/wallpapers (including nested dirs/symlinks)
# Generates thumbnails and manages current wallpaper via awww.

import sys
import os
import json
import subprocess
import re
import hashlib
import random
from pathlib import Path

WALLPAPERS_DIR = Path.home() / ".config/sicos/wallpapers"
CACHE_DIR = Path.home() / ".cache/sicos-wallpaper-thumbs"
VALID_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}

def get_current_wallpaper():
    """Query currently displayed wallpaper via awww query."""
    try:
        res = subprocess.run(["awww", "query"], capture_output=True, text=True, timeout=2)
        if res.returncode == 0:
            for line in res.stdout.strip().splitlines():
                match = re.search(r'currently displaying:\s*(?:image:\s*)?(.+)$', line)
                if match:
                    return match.group(1).strip()
    except Exception:
        pass
    return ""

def get_thumb_path(image_path):
    """Compute deterministic thumbnail path based on sha256 of file path."""
    h = hashlib.sha256(image_path.encode('utf-8')).hexdigest()[:16]
    return str(CACHE_DIR / f"{h}.jpg")

def cmd_list(filter_query=None):
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    current = get_current_wallpaper()
    items = []
    folders = set(["All", "Root"])
    
    if WALLPAPERS_DIR.exists():
        for root, dirs, files in os.walk(WALLPAPERS_DIR, followlinks=True):
            for f in files:
                ext = os.path.splitext(f)[1].lower()
                if ext in VALID_EXTENSIONS:
                    full_path = os.path.join(root, f)
                    rel_path = os.path.relpath(full_path, WALLPAPERS_DIR)
                    folder_name = os.path.dirname(rel_path)
                    folder_label = folder_name if folder_name and folder_name != "." else "Root"
                    folders.add(folder_label)
                    
                    if filter_query and filter_query.lower() not in f.lower():
                        continue

                    thumb_path = get_thumb_path(full_path)
                    has_thumb = os.path.exists(thumb_path)
                    
                    items.append({
                        "name": f,
                        "path": full_path,
                        "thumb": thumb_path if has_thumb else full_path,
                        "hasThumb": has_thumb,
                        "folder": folder_label,
                        "isCurrent": (full_path == current)
                    })
    
    # Sort alphabetically by name
    items.sort(key=lambda x: x["name"].lower())
    
    result = {
        "wallpapersDir": str(WALLPAPERS_DIR),
        "current": current,
        "count": len(items),
        "folders": sorted(list(folders)),
        "items": items
    }
    print(json.dumps(result))

def cmd_thumb(image_path):
    if not os.path.exists(image_path):
        return
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    out_path = get_thumb_path(image_path)
    if os.path.exists(out_path):
        print(out_path)
        return
    
    # Generate 320x180 thumbnail with magick
    try:
        subprocess.run(
            ["magick", image_path, "-thumbnail", "320x180^", "-gravity", "center", "-extent", "320x180", "-quality", "80", out_path],
            check=True,
            capture_output=True,
            timeout=10
        )
        print(out_path)
    except Exception as e:
        sys.stderr.write(f"Error generating thumbnail for {image_path}: {e}\n")

def cmd_batch_thumbs(limit=60):
    """Generate thumbnails for images that don't have one yet, up to limit."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    count = 0
    if WALLPAPERS_DIR.exists():
        for root, dirs, files in os.walk(WALLPAPERS_DIR, followlinks=True):
            for f in files:
                if os.path.splitext(f)[1].lower() in VALID_EXTENSIONS:
                    full_path = os.path.join(root, f)
                    thumb_path = get_thumb_path(full_path)
                    if not os.path.exists(thumb_path):
                        try:
                            subprocess.run(
                                ["magick", full_path, "-thumbnail", "320x180^", "-gravity", "center", "-extent", "320x180", "-quality", "80", thumb_path],
                                check=True,
                                capture_output=True,
                                timeout=10
                            )
                            count += 1
                            if count >= limit:
                                print(f"Generated {count} thumbs")
                                return
                        except Exception:
                            pass
    print(f"Generated {count} thumbs")

def cmd_set(image_path):
    if not os.path.exists(image_path):
        sys.exit(1)
    # awww img with smooth grow transition
    cmd = [
        "awww", "img",
        "--resize", "fit",
        "--transition-type", "grow",
        "--transition-pos", "0,0",
        "--transition-step", "90",
        image_path
    ]
    subprocess.run(cmd)

def cmd_random():
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    candidates = []
    if WALLPAPERS_DIR.exists():
        for root, dirs, files in os.walk(WALLPAPERS_DIR, followlinks=True):
            for f in files:
                if os.path.splitext(f)[1].lower() in VALID_EXTENSIONS:
                    candidates.append(os.path.join(root, f))
    if candidates:
        pick = random.choice(candidates)
        cmd_set(pick)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        cmd_list()
        sys.exit(0)
    
    action = sys.argv[1]
    if action == "--list":
        q = sys.argv[2] if len(sys.argv) >= 3 else None
        cmd_list(q)
    elif action == "--thumb" and len(sys.argv) >= 3:
        cmd_thumb(sys.argv[2])
    elif action == "--batch-thumbs":
        lim = int(sys.argv[2]) if len(sys.argv) >= 3 else 60
        cmd_batch_thumbs(lim)
    elif action == "--set" and len(sys.argv) >= 3:
        cmd_set(sys.argv[2])
    elif action == "--random":
        cmd_random()
    else:
        print(f"Unknown action: {action}", file=sys.stderr)
        sys.exit(1)
