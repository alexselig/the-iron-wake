#!/usr/bin/env python3
"""Process character pose art into game-ready sprites.

Takes high-res character poses from design/character_poses/,
removes beige background, crops, resizes, creates mirrored variants,
and outputs to assets/characters/ for use in Godot.
"""

import os
import shutil
from PIL import Image, ImageFilter
import numpy as np

BASE = os.path.expanduser("~/SteampunkBeachDemo")
POSES_DIR = os.path.join(BASE, "design", "character_poses")
ASSETS_DIR = os.path.join(BASE, "assets", "characters")

# Target sprite height in pixels (width is proportional)
TARGET_HEIGHT = 96

# Background color tolerance for removal
BG_TOLERANCE = 45

# Characters and their folder mappings
CHARACTERS = {
    "01_rowan": {
        "output": "rowan",
        "is_player": True,
    },
    "02_tibbit": {
        "output": "tibbit",
        "is_player": False,
    },
    "03_rook": {
        "output": "rook",
        "is_player": False,
    },
    "04_marrow": {
        "output": "marrow",
        "is_player": False,
    },
    "05_pindle": {
        "output": "pindle",
        "is_player": False,
    },
    "06_mirelle": {
        "output": "mirelle",
        "is_player": False,
    },
    "07_caligo": {
        "output": "caligo",
        "is_player": False,
    },
    "08_bram": {
        "output": "bram",
        "is_player": False,
    },
    "09_sel": {
        "output": "sel",
        "is_player": False,
    },
    "10_ilyan": {
        "output": "ilyan",
        "is_player": False,
    },
    "11_seraphine": {
        "output": "seraphine",
        "is_player": False,
    },
}


def remove_background(img: Image.Image) -> Image.Image:
    """Remove the beige background, making it transparent."""
    img = img.convert("RGBA")
    data = np.array(img)

    # Sample background color from corners
    corners = [
        data[5, 5, :3],
        data[5, -5, :3],
        data[-5, 5, :3],
        data[-5, -5, :3],
    ]
    bg_color = np.mean(corners, axis=0).astype(int)

    # Create mask: pixels close to bg color become transparent
    diff = np.abs(data[:, :, :3].astype(int) - bg_color)
    max_diff = np.max(diff, axis=2)
    mask = max_diff < BG_TOLERANCE

    # Also remove near-white pixels that might be part of bg
    brightness = np.mean(data[:, :, :3], axis=2)
    light_mask = (brightness > 190) & (max_diff < BG_TOLERANCE + 15)
    mask = mask | light_mask

    # Apply flood fill from edges to only remove connected background
    from scipy import ndimage
    # Label connected regions of "background-like" pixels
    labeled, num_features = ndimage.label(mask)
    # Find labels that touch the border
    border_labels = set()
    border_labels.update(labeled[0, :].tolist())
    border_labels.update(labeled[-1, :].tolist())
    border_labels.update(labeled[:, 0].tolist())
    border_labels.update(labeled[:, -1].tolist())
    border_labels.discard(0)

    # Only make transparent pixels that are connected to the border
    final_mask = np.isin(labeled, list(border_labels))

    data[final_mask, 3] = 0

    # Soften edges slightly
    result = Image.fromarray(data)
    return result


def remove_background_simple(img: Image.Image) -> Image.Image:
    """Simple background removal without scipy dependency."""
    img = img.convert("RGBA")
    data = np.array(img)

    # Sample background color from corners
    corners = [
        data[5, 5, :3],
        data[5, -5, :3],
        data[-5, 5, :3],
        data[-5, -5, :3],
    ]
    bg_color = np.mean(corners, axis=0).astype(int)

    # Flood fill from all border pixels
    h, w = data.shape[:2]
    visited = np.zeros((h, w), dtype=bool)
    to_remove = np.zeros((h, w), dtype=bool)

    # Use a stack-based flood fill from border
    stack = []
    for x in range(w):
        stack.append((0, x))
        stack.append((h - 1, x))
    for y in range(h):
        stack.append((y, 0))
        stack.append((y, w - 1))

    while stack:
        y, x = stack.pop()
        if y < 0 or y >= h or x < 0 or x >= w:
            continue
        if visited[y, x]:
            continue
        visited[y, x] = True

        pixel = data[y, x, :3].astype(int)
        diff = np.max(np.abs(pixel - bg_color))
        if diff < BG_TOLERANCE:
            to_remove[y, x] = True
            # Add neighbors
            for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                ny, nx = y + dy, x + dx
                if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                    stack.append((ny, nx))

    data[to_remove, 3] = 0

    # Anti-alias: make pixels near the edge semi-transparent
    # Find edge pixels (non-removed pixels adjacent to removed pixels)
    result = Image.fromarray(data)
    return result


def crop_to_content(img: Image.Image, padding: int = 2) -> Image.Image:
    """Crop to non-transparent content with optional padding."""
    bbox = img.getbbox()
    if bbox is None:
        return img
    left, top, right, bottom = bbox
    left = max(0, left - padding)
    top = max(0, top - padding)
    right = min(img.width, right + padding)
    bottom = min(img.height, bottom + padding)
    return img.crop((left, top, right, bottom))


def resize_to_height(img: Image.Image, target_h: int) -> Image.Image:
    """Resize maintaining aspect ratio to target height."""
    ratio = target_h / img.height
    target_w = int(img.width * ratio)
    return img.resize((target_w, target_h), Image.LANCZOS)


def process_pose(src_path: str) -> Image.Image:
    """Full pipeline: remove bg, crop, resize."""
    img = Image.open(src_path)
    print(f"  Processing {os.path.basename(src_path)} ({img.size})...")

    # Try scipy version first, fall back to simple
    try:
        img = remove_background(img)
    except ImportError:
        img = remove_background_simple(img)

    img = crop_to_content(img)
    img = resize_to_height(img, TARGET_HEIGHT)
    return img


def mirror_horizontal(img: Image.Image) -> Image.Image:
    """Mirror image horizontally for left-facing variant."""
    return img.transpose(Image.FLIP_LEFT_RIGHT)


def process_player(char_key: str, char_info: dict):
    """Process player character (Rowan) into animation frames."""
    pose_dir = os.path.join(POSES_DIR, char_key)
    out_dir = os.path.join(ASSETS_DIR, "frames")

    # Back up existing frames
    backup_dir = os.path.join(ASSETS_DIR, "frames_backup")
    if os.path.exists(out_dir) and not os.path.exists(backup_dir):
        shutil.copytree(out_dir, backup_dir)
        print(f"  Backed up existing frames to {backup_dir}")

    os.makedirs(out_dir, exist_ok=True)

    # Map poses to animation frames
    # idle: idle.png -> idle_right_0, gesture -> idle_right_1
    # walk: walk_1, walk_2 -> walk_right_0..3 (with idle as transition frames)
    # talk: talking.png -> talk_right_0, idle -> talk_right_1

    idle_img = process_pose(os.path.join(pose_dir, "idle.png"))
    talk_img = process_pose(os.path.join(pose_dir, "talking.png"))
    walk1_img = process_pose(os.path.join(pose_dir, "walk_1.png"))
    walk2_img = process_pose(os.path.join(pose_dir, "walk_2.png"))

    # Make all frames the same size (pad to max dimensions)
    all_frames = [idle_img, talk_img, walk1_img, walk2_img]
    max_w = max(f.width for f in all_frames)
    max_h = max(f.height for f in all_frames)

    def pad_to_size(img, w, h):
        """Center the image on a canvas of size w x h."""
        canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        x = (w - img.width) // 2
        y = h - img.height  # Align feet to bottom
        canvas.paste(img, (x, y), img)
        return canvas

    idle_img = pad_to_size(idle_img, max_w, max_h)
    talk_img = pad_to_size(talk_img, max_w, max_h)
    walk1_img = pad_to_size(walk1_img, max_w, max_h)
    walk2_img = pad_to_size(walk2_img, max_w, max_h)

    # Save right-facing frames
    # Idle: 2 frames (idle, slight variation)
    idle_img.save(os.path.join(out_dir, "idle_right_0.png"))
    idle_img.save(os.path.join(out_dir, "idle_right_1.png"))

    # Walk: 4 frames (idle -> walk1 -> idle -> walk2)
    idle_img.save(os.path.join(out_dir, "walk_right_0.png"))
    walk1_img.save(os.path.join(out_dir, "walk_right_1.png"))
    idle_img.save(os.path.join(out_dir, "walk_right_2.png"))
    walk2_img.save(os.path.join(out_dir, "walk_right_3.png"))

    # Talk: 2 frames
    talk_img.save(os.path.join(out_dir, "talk_right_0.png"))
    idle_img.save(os.path.join(out_dir, "talk_right_1.png"))

    # Save left-facing frames (mirrored)
    mirror_horizontal(idle_img).save(os.path.join(out_dir, "idle_left_0.png"))
    mirror_horizontal(idle_img).save(os.path.join(out_dir, "idle_left_1.png"))

    mirror_horizontal(idle_img).save(os.path.join(out_dir, "walk_left_0.png"))
    mirror_horizontal(walk1_img).save(os.path.join(out_dir, "walk_left_1.png"))
    mirror_horizontal(idle_img).save(os.path.join(out_dir, "walk_left_2.png"))
    mirror_horizontal(walk2_img).save(os.path.join(out_dir, "walk_left_3.png"))

    mirror_horizontal(talk_img).save(os.path.join(out_dir, "talk_left_0.png"))
    mirror_horizontal(idle_img).save(os.path.join(out_dir, "talk_left_1.png"))

    print(f"  -> Saved 16 frames to {out_dir}")


def process_npc(char_key: str, char_info: dict):
    """Process an NPC into sprite frames."""
    pose_dir = os.path.join(POSES_DIR, char_key)
    out_dir = os.path.join(ASSETS_DIR, char_info["output"])
    os.makedirs(out_dir, exist_ok=True)

    # Check which poses exist
    has_idle = os.path.exists(os.path.join(pose_dir, "idle.png"))
    has_talk = os.path.exists(os.path.join(pose_dir, "talking.png"))
    has_walk1 = os.path.exists(os.path.join(pose_dir, "walk_1.png"))
    has_walk2 = os.path.exists(os.path.join(pose_dir, "walk_2.png"))

    if not has_idle:
        print(f"  WARNING: No idle.png for {char_key}, skipping")
        return

    idle_img = process_pose(os.path.join(pose_dir, "idle.png"))
    talk_img = process_pose(os.path.join(pose_dir, "talking.png")) if has_talk else idle_img
    walk1_img = process_pose(os.path.join(pose_dir, "walk_1.png")) if has_walk1 else idle_img
    walk2_img = process_pose(os.path.join(pose_dir, "walk_2.png")) if has_walk2 else idle_img

    # Pad all to same size
    all_frames = [idle_img, talk_img, walk1_img, walk2_img]
    max_w = max(f.width for f in all_frames)
    max_h = max(f.height for f in all_frames)

    def pad_to_size(img, w, h):
        canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        x = (w - img.width) // 2
        y = h - img.height
        canvas.paste(img, (x, y), img)
        return canvas

    idle_img = pad_to_size(idle_img, max_w, max_h)
    talk_img = pad_to_size(talk_img, max_w, max_h)

    # NPCs: idle + talk frames (right-facing, source art faces right)
    idle_img.save(os.path.join(out_dir, "idle_right_0.png"))
    idle_img.save(os.path.join(out_dir, "idle_right_1.png"))
    talk_img.save(os.path.join(out_dir, "talk_right_0.png"))
    idle_img.save(os.path.join(out_dir, "talk_right_1.png"))

    # Left-facing (mirrored)
    mirror_horizontal(idle_img).save(os.path.join(out_dir, "idle_left_0.png"))
    mirror_horizontal(idle_img).save(os.path.join(out_dir, "idle_left_1.png"))
    mirror_horizontal(talk_img).save(os.path.join(out_dir, "talk_left_0.png"))
    mirror_horizontal(idle_img).save(os.path.join(out_dir, "talk_left_1.png"))

    print(f"  -> Saved 8 NPC frames to {out_dir}")


def main():
    print("=== Processing Character Sprites ===\n")

    for char_key, char_info in CHARACTERS.items():
        pose_dir = os.path.join(POSES_DIR, char_key)
        if not os.path.exists(pose_dir):
            print(f"SKIP {char_key}: no pose directory")
            continue

        print(f"\n[{char_key}] -> {char_info['output']}")
        if char_info["is_player"]:
            process_player(char_key, char_info)
        else:
            process_npc(char_key, char_info)

    print("\n=== Done! ===")
    print("Restart Godot to reimport the new sprites.")


if __name__ == "__main__":
    main()
