#!/usr/bin/env python3

# sicos-wallpapers.py - Wallpaper backend for SicOS-Bar
#
# Scans ~/.config/sicos/wallpapers (including nested dirs/symlinks)
# Generates thumbnails and manages current wallpaper via awww.
# Supports querying available outputs, targeting specific outputs or all outputs,
# and choosing image resize modes (fit, crop, stretch, no).

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

def get_outputs_and_wallpapers():
    """Query currently displayed wallpapers and available outputs via awww query and hyprctl."""
    outputs = []
    output_wallpapers = {}
    current = ""
    try:
        res = subprocess.run(["awww", "query"], capture_output=True, text=True, timeout=2)
        if res.returncode == 0:
            for line in res.stdout.strip().splitlines():
                m = re.match(r"^:?\s*([^:]+):\s*([^,]+),\s*scale:\s*([^,]+),\s*currently displaying:\s*(?:image:\s*)?(.+)$", line)
                if m:
                    out_name, res_str, scale_str, img_path = m.groups()
                    out_name = out_name.strip()
                    img_path = img_path.strip()
                    if out_name not in outputs:
                        outputs.append(out_name)
                    output_wallpapers[out_name] = img_path
                    if not current:
                        current = img_path
    except Exception:
        pass

    # Fallback / supplement with hyprctl monitors if needed
    try:
        h_res = subprocess.run(["hyprctl", "monitors", "-j"], capture_output=True, text=True, timeout=2)
        if h_res.returncode == 0:
            mon_data = json.loads(h_res.stdout)
            for m in mon_data:
                m_name = m.get("name")
                if m_name and m_name not in outputs:
                    outputs.append(m_name)
    except Exception:
        pass

    return outputs, output_wallpapers, current

def get_thumb_path(image_path):
    """Compute deterministic thumbnail path based on sha256 of file path."""
    h = hashlib.sha256(image_path.encode('utf-8')).hexdigest()[:16]
    return str(CACHE_DIR / f"{h}.jpg")

def cmd_list(filter_query=None):
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    outputs, output_wallpapers, current = get_outputs_and_wallpapers()
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
        "outputs": outputs,
        "outputWallpapers": output_wallpapers,
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

def cmd_set(image_path, target_output=None, resize_mode="fit"):
    if not os.path.exists(image_path):
        sys.exit(1)
    
    valid_resizes = {"fit", "crop", "stretch", "no"}
    if resize_mode not in valid_resizes:
        resize_mode = "fit"

    cmd = ["awww", "img"]
    
    # Target output specification (if specified and not "all" or empty)
    if target_output and target_output.lower() not in ("all", "*", ""):
        cmd.extend(["-o", target_output])
        
    cmd.extend([
        "--resize", resize_mode,
        "--transition-type", "grow",
        "--transition-pos", "0,0",
        "--transition-step", "90",
        image_path
    ])
    subprocess.run(cmd)

def cmd_random(target_output=None, resize_mode="fit"):
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    candidates = []
    if WALLPAPERS_DIR.exists():
        for root, dirs, files in os.walk(WALLPAPERS_DIR, followlinks=True):
            for f in files:
                if os.path.splitext(f)[1].lower() in VALID_EXTENSIONS:
                    candidates.append(os.path.join(root, f))
    if candidates:
        pick = random.choice(candidates)
        cmd_set(pick, target_output=target_output, resize_mode=resize_mode)

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="SicOS wallpaper manager backend")
    parser.add_argument("--list", action="store_true", help="List wallpapers and outputs")
    parser.add_argument("--thumb", type=str, help="Generate thumbnail for single image")
    parser.add_argument("--batch-thumbs", type=int, nargs="?", const=60, help="Batch generate thumbnails")
    parser.add_argument("--set", type=str, help="Set wallpaper image path")
    parser.add_argument("--random", action="store_true", help="Pick and set random wallpaper")
    parser.add_argument("-o", "--output", type=str, default=None, help="Target output (e.g. eDP-1, DP-1, or 'all')")
    parser.add_argument("-r", "--resize", type=str, default="fit", help="Resize mode (fit, crop, stretch, no)")
    parser.add_argument("query", nargs="?", default=None, help="Optional search query filter for --list")

    args = parser.parse_args()

    if args.set:
        cmd_set(args.set, target_output=args.output, resize_mode=args.resize)
    elif args.random:
        cmd_random(target_output=args.output, resize_mode=args.resize)
    elif args.thumb:
        cmd_thumb(args.thumb)
    elif args.batch_thumbs is not None:
        cmd_batch_thumbs(args.batch_thumbs)
    elif args.list:
        cmd_list(args.query)
    else:
        cmd_list(args.query)
